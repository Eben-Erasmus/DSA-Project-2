import ballerina/http;
import ballerina/log;
import ballerinax/mongodb as mongo;
import ballerinax/kafka;

listener http:Listener transportListener = new(8082);
string mongoUrl2 = checkpanic getenv("MONGO_URL", "mongodb://mongo:27017");
mongo:Client dbClient2 = checkpanic new (mongoUrl2);

string kafkaBootstrap2 = checkpanic getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092");
kafka:ProducerConfig pconf2 = {bootstrapServers: kafkaBootstrap2};
kafka:Producer scheduleProducer = checkpanic new (pconf2);

public type Route record { string routeId; string name; string[] stops = []; };
public type Trip record { string tripId; string routeId; string departureTime; string status; };

service /transport on transportListener {

    resource function post routes(http:Request req) returns http:Response|error {
        json payload = check req.getJsonPayload();
        string name = <string>payload.name;
        string[] stops = [];
        if (payload.stops is json[]) {
            foreach var s in <json[]>payload.stops { stops.push(<string>s); }
        }
        string routeId = "r" + (time:currentTimeMillis()).toString();
        json doc = { routeId: routeId, name: name, stops: stops };
        check dbClient2->insertOne("smartticket", "routes", doc);
        http:Response res = new;
        res.statusCode = 201;
        res.setJsonPayload(doc);
        return res;
    }

    resource function get routes() returns http:Response|error {
        var docs = dbClient2->find("smartticket", "routes", {});
        if docs is error {
            http:Response res = new;
            res.statusCode = 500;
            res.setJsonPayload({ error: "Failed to fetch routes" });
            return res;
        }
        http:Response res = new;
        res.statusCode = 200;
        res.setJsonPayload(docs);
        return res;
    }

    resource function post trips(http:Request req) returns http:Response|error {
        json payload = check req.getJsonPayload();
        string routeId = <string>payload.routeId;
        string departureTime = <string>payload.departureTime;
        // verify route exists
        var route = dbClient2->findOne("smartticket", "routes", { "routeId": routeId });
        if route is error {
            http:Response res = new;
            res.statusCode = 400;
            res.setJsonPayload({ error: "Unknown routeId" });
            return res;
        }
        string tripId = "t" + (time:currentTimeMillis()).toString();
        json doc = { tripId: tripId, routeId: routeId, departureTime: departureTime, status: "SCHEDULED" };
        check dbClient2->insertOne("smartticket", "trips", doc);
        http:Response res = new;
        res.statusCode = 201;
        res.setJsonPayload(doc);
        return res;
    }

    resource function post scheduleUpdate(http:Request req, string tripId) returns http:Response|error {
        json payload = check req.getJsonPayload();
        string newStatus = <string>payload.status;
        var upd = dbClient2->updateOne("smartticket", "trips", { "tripId": tripId }, { "$set": { "status": newStatus } });
        if upd is error {
            http:Response res = new;
            res.statusCode = 500;
            res.setJsonPayload({ error: "Failed to update trip" });
            return res;
        }
        // publish schedule update to Kafka
        json ev = { tripId: tripId, status: newStatus, timestamp: time:currentTimeMillis() };
        var sendRes = scheduleProducer->send({ topic: "schedule.updates", value: ev.toJsonString() });
        if sendRes is error {
            log:printError("Failed to publish schedule update: " + sendRes.message());
        }
        http:Response res = new;
        res.statusCode = 200;
        res.setJsonPayload({ message: "Schedule updated", tripId: tripId, status: newStatus });
        return res;
    }
}
