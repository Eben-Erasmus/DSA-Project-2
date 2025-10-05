import ballerina/http;
import ballerina/log;
import ballerina/uuid;
import ballerina/time;
import ballerinax/mongodb;
import ballerinax/kafka;

configurable string mongoUrl = "mongodb://admin:password@localhost:27017/ticketing?authSource=admin";
configurable string kafkaBootstrapServers = "localhost:9092";

type Ticket record {
    string id;
    string passengerId;
    string tripId;
    string ticketType;
    string status;
    decimal price;
    time:Utc purchaseTime;
    time:Utc? validationTime;
};

type TicketRequest record {
    string passengerId;
    string tripId;
    string ticketType;
    decimal price;
};

type TicketValidation record {
    string ticketId;
    string validatedBy;
};

mongodb:Client mongoClient = check new (mongoUrl);
kafka:Producer kafkaProducer = check new (kafka:ProducerConfiguration {
    bootstrapServers: kafkaBootstrapServers
});
kafka:Consumer kafkaConsumer = check new (kafka:ConsumerConfiguration {
    bootstrapServers: kafkaBootstrapServers,
    groupId: "ticketing-service",
    topics: ["payments.processed"]
});

function insertTicket(Ticket ticket) returns error? {
    mongodb:Database database = check mongoClient->getDatabase("ticketing");
    mongodb:Collection tickets = check database->getCollection("tickets");
    check tickets->insertOne(ticket);
}

function findTicketById(string id) returns Ticket|error? {
    mongodb:Database database = check mongoClient->getDatabase("ticketing");
    mongodb:Collection tickets = check database->getCollection("tickets");
    map<json> filter = {"id": id};
    Ticket? ticket = check tickets->findOne(filter, {}, (), Ticket);
    return ticket;
}

function updateTicketStatus(string ticketId, string status) returns error? {
    mongodb:Database database = check mongoClient->getDatabase("ticketing");
    mongodb:Collection tickets = check database->getCollection("tickets");
    map<json> filter = {"id": ticketId};
    map<json> update = {"$set": {"status": status}};
    check tickets->updateOne(filter, update);
}

function updateTicketValidation(string ticketId, time:Utc validationTime) returns error? {
    mongodb:Database database = check mongoClient->getDatabase("ticketing");
    mongodb:Collection tickets = check database->getCollection("tickets");
    map<json> filter = {"id": ticketId};
    map<json> update = {"$set": {"status": "VALIDATED", "validationTime": validationTime}};
    check tickets->updateOne(filter, update);
}

function publishTicketEvent(string eventType, json eventData) {
    kafka:ProducerRecord producerRecord = {
        topic: "ticket.events",
        value: {
            "eventType": eventType,
            "data": eventData,
            "timestamp": time:utcNow()
        }
    };
    
    kafka:Error? result = kafkaProducer->send(producerRecord);
    if result is error {
        log:printError("Failed to publish ticket event", result);
    }
}

function publishTicketRequest(json ticketData) {
    kafka:ProducerRecord producerRecord = {
        topic: "ticket.requests",
        value: ticketData
    };
    
    kafka:Error? result = kafkaProducer->send(producerRecord);
    if result is error {
        log:printError("Failed to publish ticket request", result);
    }
}

service /tickets on new http:Listener(8083) {

    resource function post .() returns json|http:BadRequest|http:InternalServerError {
        log:printInfo("Creating new ticket");
        
        return {"message": "Ticket creation endpoint"};
    }
    
    resource function post purchase(TicketRequest ticketRequest) returns http:Created|http:BadRequest|http:InternalServerError {
        log:printInfo("Processing ticket purchase for passenger: " + ticketRequest.passengerId);
        
        if ticketRequest.price <= 0 {
            return http:BAD_REQUEST;
        }
        
        string ticketId = uuid:createType1AsString();
        Ticket ticket = {
            id: ticketId,
            passengerId: ticketRequest.passengerId,
            tripId: ticketRequest.tripId,
            ticketType: ticketRequest.ticketType,
            status: "CREATED",
            price: ticketRequest.price,
            purchaseTime: time:utcNow(),
            validationTime: ()
        };
        
        error? insertResult = insertTicket(ticket);
        if insertResult is error {
            log:printError("Error inserting ticket", insertResult);
            return http:INTERNAL_SERVER_ERROR;
        }
        
        publishTicketRequest({
            "ticketId": ticketId,
            "passengerId": ticketRequest.passengerId,
            "tripId": ticketRequest.tripId,
            "price": ticketRequest.price,
            "timestamp": time:utcNow()
        });
        
        publishTicketEvent("TICKET_CREATED", {
            "ticketId": ticketId,
            "passengerId": ticketRequest.passengerId,
            "tripId": ticketRequest.tripId,
            "status": "CREATED"
        });
        
        return http:CREATED;
    }
    
    resource function put [string ticketId]/validate(TicketValidation validation) returns http:Ok|http:NotFound|http:BadRequest|http:InternalServerError {
        log:printInfo("Validating ticket: " + ticketId);
        
        Ticket|error? ticketResult = findTicketById(ticketId);
        if ticketResult is error {
            log:printError("Error finding ticket", ticketResult);
            return http:INTERNAL_SERVER_ERROR;
        }
        
        if ticketResult is () {
            return http:NOT_FOUND;
        }
        
        Ticket ticket = ticketResult;
        
        if ticket.status != "PAID" {
            return http:BAD_REQUEST;
        }
        
        error? updateResult = updateTicketValidation(ticketId, time:utcNow());
        if updateResult is error {
            log:printError("Error updating ticket validation", updateResult);
            return http:INTERNAL_SERVER_ERROR;
        }
        
        publishTicketEvent("TICKET_VALIDATED", {
            "ticketId": ticketId,
            "passengerId": ticket.passengerId,
            "tripId": ticket.tripId,
            "validatedBy": validation.validatedBy,
            "validationTime": time:utcNow()
        });
        
        return http:OK;
    }
    
    resource function get [string ticketId]() returns json|http:NotFound|http:InternalServerError {
        log:printInfo("Getting ticket details: " + ticketId);
        
        Ticket|error? ticketResult = findTicketById(ticketId);
        if ticketResult is error {
            log:printError("Error finding ticket", ticketResult);
            return http:INTERNAL_SERVER_ERROR;
        }
        
        if ticketResult is () {
            return http:NOT_FOUND;
        }
        
        return ticketResult.toJson();
    }
    
    resource function get health() returns json {
        return {"status": "healthy", "service": "ticketing-service"};
    }
}

service on new kafka:Listener(kafkaConsumer) {
    remote function onConsumerRecord(kafka:ConsumerRecord[] records) {
        foreach kafka:ConsumerRecord consumerRecord in records {
            processPaymentRecord(consumerRecord);
        }
    }
}

function processPaymentRecord(kafka:ConsumerRecord consumerRecord) {
    json|error payload = consumerRecord.value.fromJsonString();
    if payload is error {
        log:printError("Error parsing payment record", payload);
        return;
    }
    
    json paymentData = payload;
    string? ticketId = <string?>paymentData.ticketId;
    string? status = <string?>paymentData.status;
    
    if ticketId is string && status is string {
        if status == "COMPLETED" {
            error? updateResult = updateTicketStatus(ticketId, "PAID");
            if updateResult is error {
                log:printError("Error updating ticket status", updateResult);
                return;
            }
            
            publishTicketEvent("TICKET_PAID", {
                "ticketId": ticketId,
                "status": "PAID"
            });
            
            log:printInfo("Ticket " + ticketId + " marked as PAID");
        }
    }
}
