import ballerina/http;
import ballerina/log;
import ballerina/uuid;
import ballerina/time;
import ballerinax/mongodb;
import ballerinax/kafka;

configurable string mongoUrl = "mongodb://admin:password@localhost:27017/ticketing?authSource=admin";
configurable string kafkaBootstrapServers = "localhost:9092";

type Payment record {
    string id;
    string ticketId;
    string passengerId;
    decimal amount;
    string status;
    string paymentMethod;
    time:Utc createdAt;
    time:Utc? processedAt;
};

type PaymentRequest record {
    string ticketId;
    string passengerId;
    decimal amount;
    string paymentMethod;
};

mongodb:Client mongoClient = check new (mongoUrl);
kafka:Producer kafkaProducer = check new (kafka:ProducerConfiguration {
    bootstrapServers: kafkaBootstrapServers
});
kafka:Consumer kafkaConsumer = check new (kafka:ConsumerConfiguration {
    bootstrapServers: kafkaBootstrapServers,
    groupId: "payment-service",
    topics: ["ticket.requests"]
});

function insertPayment(Payment payment) returns error? {
    mongodb:Database database = check mongoClient->getDatabase("ticketing");
    mongodb:Collection payments = check database->getCollection("payments");
    check payments->insertOne(payment);
}

function findPaymentById(string id) returns Payment|error? {
    mongodb:Database database = check mongoClient->getDatabase("ticketing");
    mongodb:Collection payments = check database->getCollection("payments");
    map<json> filter = {"id": id};
    Payment? payment = check payments->findOne(filter, {}, (), Payment);
    return payment;
}

function updatePaymentStatus(string paymentId, string status, time:Utc processedAt) returns error? {
    mongodb:Database database = check mongoClient->getDatabase("ticketing");
    mongodb:Collection payments = check database->getCollection("payments");
    map<json> filter = {"id": paymentId};
    map<json> update = {"$set": {"status": status, "processedAt": processedAt}};
    check payments->updateOne(filter, update);
}

function publishPaymentEvent(string eventType, json eventData) {
    kafka:ProducerRecord producerRecord = {
        topic: "payments.processed",
        value: {
            "eventType": eventType,
            "data": eventData,
            "timestamp": time:utcNow()
        }
    };
    
    kafka:Error? result = kafkaProducer->send(producerRecord);
    if result is error {
        log:printError("Failed to publish payment event", result);
    }
}

function processPayment(Payment payment) returns boolean {
    log:printInfo("Processing payment: " + payment.id);
    
    // Simulate payment processing (always succeeds for demo)
    return true;
}

service /payments on new http:Listener(8084) {

    resource function post .() returns json|http:BadRequest|http:InternalServerError {
        log:printInfo("Payment endpoint accessed");
        return {"message": "Payment service"};
    }
    
    resource function post process(PaymentRequest paymentRequest) returns http:Created|http:BadRequest|http:InternalServerError {
        log:printInfo("Processing payment for ticket: " + paymentRequest.ticketId);
        
        if paymentRequest.amount <= 0 {
            return http:BAD_REQUEST;
        }
        
        string paymentId = uuid:createType1AsString();
        Payment payment = {
            id: paymentId,
            ticketId: paymentRequest.ticketId,
            passengerId: paymentRequest.passengerId,
            amount: paymentRequest.amount,
            status: "PENDING",
            paymentMethod: paymentRequest.paymentMethod,
            createdAt: time:utcNow(),
            processedAt: ()
        };
        
        error? insertResult = insertPayment(payment);
        if insertResult is error {
            log:printError("Error inserting payment", insertResult);
            return http:INTERNAL_SERVER_ERROR;
        }
        
        // Simulate payment processing
        boolean paymentSuccess = processPayment(payment);
        string status = paymentSuccess ? "COMPLETED" : "FAILED";
        
        error? updateResult = updatePaymentStatus(paymentId, status, time:utcNow());
        if updateResult is error {
            log:printError("Error updating payment status", updateResult);
            return http:INTERNAL_SERVER_ERROR;
        }
        
        publishPaymentEvent("PAYMENT_PROCESSED", {
            "paymentId": paymentId,
            "ticketId": paymentRequest.ticketId,
            "status": status,
            "amount": paymentRequest.amount
        });
        
        return http:CREATED;
    }
    
    resource function get [string paymentId]() returns json|http:NotFound|http:InternalServerError {
        log:printInfo("Getting payment details: " + paymentId);
        
        Payment|error? paymentResult = findPaymentById(paymentId);
        if paymentResult is error {
            log:printError("Error finding payment", paymentResult);
            return http:INTERNAL_SERVER_ERROR;
        }
        
        if paymentResult is () {
            return http:NOT_FOUND;
        }
        
        return paymentResult.toJson();
    }
    
    resource function get health() returns json {
        return {"status": "healthy", "service": "payment-service"};
    }
}

service on new kafka:Listener(kafkaConsumer) {
    remote function onConsumerRecord(kafka:ConsumerRecord[] records) {
        foreach kafka:ConsumerRecord consumerRecord in records {
            processTicketRequest(consumerRecord);
        }
    }
}

function processTicketRequest(kafka:ConsumerRecord consumerRecord) {
    json|error payload = consumerRecord.value.fromJsonString();
    if payload is error {
        log:printError("Error parsing ticket request", payload);
        return;
    }
    
    json ticketData = payload;
    string? ticketId = <string?>ticketData.ticketId;
    string? passengerId = <string?>ticketData.passengerId;
    decimal? price = <decimal?>ticketData.price;
    
    if ticketId is string && passengerId is string && price is decimal {
        log:printInfo("Auto-processing payment for ticket: " + ticketId);
        
        string paymentId = uuid:createType1AsString();
        Payment payment = {
            id: paymentId,
            ticketId: ticketId,
            passengerId: passengerId,
            amount: price,
            status: "COMPLETED",
            paymentMethod: "AUTO",
            createdAt: time:utcNow(),
            processedAt: time:utcNow()
        };
        
        error? insertResult = insertPayment(payment);
        if insertResult is error {
            log:printError("Error inserting auto payment", insertResult);
            return;
        }
        
        publishPaymentEvent("PAYMENT_PROCESSED", {
            "paymentId": paymentId,
            "ticketId": ticketId,
            "status": "COMPLETED",
            "amount": price
        });
        
        log:printInfo("Auto payment completed for ticket: " + ticketId);
    }
}
