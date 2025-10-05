import ballerina/http;
import ballerina/log;
import ballerina/time;

// Admin Service with database and messaging architecture
configurable string mongoUrl = "mongodb://mongodb:27017/ticketing";
configurable string kafkaBootstrapServers = "localhost:9092";

type SalesReport record {|
    int totalTickets;
    decimal totalRevenue;
    map<int> ticketsByType;
    string generatedAt;
|};

type TrafficReport record {|
    int totalPassengers;
    map<int> passengersByRoute;
    string generatedAt;
|};

type ServiceDisruption record {|
    string routeId;
    string disruptionType;
    string title;
    string description;
    string startTime;
    string? endTime;
|};

function generateSalesReport() returns SalesReport|error {
    log:printInfo("Generating sales report from database");
    
    // Simulate database operations for demo
    map<int> ticketsByType = {};
    ticketsByType["SINGLE"] = 150;
    ticketsByType["MULTI"] = 75;
    ticketsByType["PASS"] = 25;
    
    return {
        totalTickets: 250,
        totalRevenue: 2500.00,
        ticketsByType: ticketsByType,
        generatedAt: time:utcNow().toString()
    };
}

function generateTrafficReport() returns TrafficReport|error {
    log:printInfo("Generating traffic report from database");
    
    // Simulate database operations for demo
    map<int> passengersByRoute = {};
    passengersByRoute["route-1"] = 45;
    passengersByRoute["route-2"] = 32;
    passengersByRoute["route-3"] = 28;
    
    return {
        totalPassengers: 105,
        passengersByRoute: passengersByRoute,
        generatedAt: time:utcNow().toString()
    };
}

function publishServiceDisruption(ServiceDisruption disruption) returns error? {
    log:printInfo(string `Publishing service disruption for route: ${disruption.routeId}`);
    
    // Simulate Kafka message publishing for demo
    log:printInfo(string `Service disruption published: ${disruption.title}`);
    return;
}

service /admin on new http:Listener(8086) {

    resource function get reports/sales() returns http:Response {
        http:Response response = new;
        log:printInfo("Getting sales report");
        
        SalesReport|error reportResult = generateSalesReport();
        if reportResult is error {
            log:printError("Error generating sales report", reportResult);
            response.statusCode = 500;
            response.setJsonPayload({"error": "Failed to generate sales report"});
        } else {
            response.statusCode = 200;
            response.setJsonPayload(reportResult.toJson());
        }
        
        return response;
    }
    
    resource function get reports/traffic() returns http:Response {
        http:Response response = new;
        log:printInfo("Getting traffic report");
        
        TrafficReport|error reportResult = generateTrafficReport();
        if reportResult is error {
            log:printError("Error generating traffic report", reportResult);
            response.statusCode = 500;
            response.setJsonPayload({"error": "Failed to generate traffic report"});
        } else {
            response.statusCode = 200;
            response.setJsonPayload(reportResult.toJson());
        }
        
        return response;
    }
    
    resource function post disruptions(ServiceDisruption disruption) returns http:Response {
        http:Response response = new;
        log:printInfo(string `Creating service disruption for route: ${disruption.routeId}`);
        
        if disruption.title.length() == 0 || disruption.description.length() == 0 {
            response.statusCode = 400;
            response.setJsonPayload({"error": "Title and description are required"});
            return response;
        }
        
        error? publishResult = publishServiceDisruption(disruption);
        if publishResult is error {
            response.statusCode = 500;
            response.setJsonPayload({"error": "Failed to publish service disruption"});
        } else {
            response.statusCode = 201;
            response.setJsonPayload({"message": "Service disruption published successfully"});
        }
        
        return response;
    }
    
    resource function get health() returns http:Response {
        http:Response response = new;
        response.statusCode = 200;
        response.setJsonPayload({
            "service": "admin-service",
            "status": "healthy", 
            "timestamp": time:utcNow().toString(),
            "database": mongoUrl,
            "messaging": kafkaBootstrapServers,
            "features": ["sales_reports", "traffic_reports", "service_disruptions", "dashboard"]
        });
        return response;
    }
    
    resource function get dashboard() returns http:Response {
        http:Response response = new;
        log:printInfo("Getting admin dashboard data");
        
        SalesReport|error salesReport = generateSalesReport();
        TrafficReport|error trafficReport = generateTrafficReport();
        
        map<anydata> summary = {};
        summary["totalTickets"] = salesReport is SalesReport ? salesReport.totalTickets : 0;
        summary["totalRevenue"] = salesReport is SalesReport ? salesReport.totalRevenue : 0.0;
        summary["totalPassengers"] = trafficReport is TrafficReport ? trafficReport.totalPassengers : 0;
        
        map<anydata> dashboard = {};
        dashboard["summary"] = summary;
        dashboard["timestamp"] = time:utcNow().toString();
        dashboard["status"] = "operational";
        
        response.statusCode = 200;
        response.setJsonPayload(dashboard.toJson());
        return response;
    }
}
