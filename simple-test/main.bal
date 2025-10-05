import ballerina/http;

service /test on new http:Listener(8090) {
    
    resource function get hello() returns string {
        return "Hello World!";
    }
    
    resource function get health() returns json {
        return {"status": "ok"};
    }
}
