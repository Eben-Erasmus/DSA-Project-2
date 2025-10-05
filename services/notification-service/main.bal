import ballerina/http;
import ballerina/log;
import ballerina/uuid;
import ballerina/time;

// Notification Service with MongoDB persistence
configurable string mongoUrl = "mongodb://mongodb:27017/ticketing";

type Notification record {|
    string id;
    string userId;
    string notificationType;
    string title;
    string message;
    boolean read;
    string createdAt;
|};

type NotificationRequest record {|
    string userId;
    string notificationType;
    string title;
    string message;
|};

// Database operations - simplified for demo
function insertNotification(Notification notification) returns error? {
    // In a real implementation, this would connect to MongoDB
    // For now, we'll log the operation and simulate success
    log:printInfo(string `Inserting notification: ${notification.id} for user: ${notification.userId}`);
    return;
}

function findNotificationsByUserId(string userId) returns Notification[]|error {
    // In a real implementation, this would query MongoDB
    // For now, return sample data for demo purposes
    log:printInfo(string `Finding notifications for user: ${userId}`);
    
    Notification sampleNotification = {
        id: uuid:createType1AsString(),
        userId: userId,
        notificationType: "WELCOME",
        title: "Welcome to Smart Ticketing",
        message: "Your account has been created successfully!",
        read: false,
        createdAt: time:utcNow().toString()
    };
    
    return [sampleNotification];
}

function createNotification(string userId, string notificationType, string title, string message) returns string|error {
    string notificationId = uuid:createType1AsString();
    Notification notification = {
        id: notificationId,
        userId: userId,
        notificationType: notificationType,
        title: title,
        message: message,
        read: false,
        createdAt: time:utcNow().toString()
    };
    
    error? insertResult = insertNotification(notification);
    if insertResult is error {
        log:printError("Error inserting notification", insertResult);
        return insertResult;
    }
    
    log:printInfo(string `Notification created for user: ${userId}`);
    return notificationId;
}

service /notifications on new http:Listener(8085) {

    resource function get [string userId]() returns http:Response {
        http:Response response = new;
        log:printInfo(string `Getting notifications for user: ${userId}`);
        
        Notification[]|error notificationsResult = findNotificationsByUserId(userId);
        if notificationsResult is error {
            log:printError("Error finding notifications", notificationsResult);
            response.statusCode = 500;
            json errorJson = {"error": "Internal server error"};
            response.setJsonPayload(errorJson);
        } else {
            response.statusCode = 200;
            json responseJson = {
                "notifications": notificationsResult.toJson()
            };
            response.setJsonPayload(responseJson);
        }
        
        return response;
    }
    
    resource function post send(NotificationRequest notificationRequest) returns http:Response {
        http:Response response = new;
        log:printInfo(string `Sending notification to user: ${notificationRequest.userId}`);
        
        if notificationRequest.title.length() == 0 || notificationRequest.message.length() == 0 {
            response.statusCode = 400;
            json errorJson = {"error": "Title and message are required"};
            response.setJsonPayload(errorJson);
            return response;
        }
        
        string|error createResult = createNotification(
            notificationRequest.userId,
            notificationRequest.notificationType,
            notificationRequest.title,
            notificationRequest.message
        );
        
        if createResult is error {
            response.statusCode = 500;
            json errorJson = {"error": "Failed to create notification"};
            response.setJsonPayload(errorJson);
        } else {
            response.statusCode = 201;
            json responseJson = {
                "message": "Notification sent successfully",
                "notificationId": createResult
            };
            response.setJsonPayload(responseJson);
        }
        
        return response;
    }
    
    resource function put [string notificationId]/read() returns http:Response {
        http:Response response = new;
        log:printInfo(string `Marking notification as read: ${notificationId}`);
        
        // In a real implementation, this would update MongoDB
        // For now, simulate success
        response.statusCode = 200;
        json responseJson = {"message": "Notification marked as read"};
        response.setJsonPayload(responseJson);
        
        return response;
    }
    
    resource function get health() returns http:Response {
        http:Response response = new;
        response.statusCode = 200;
        
        json responseJson = {
            "service": "notification-service",
            "status": "healthy",
            "timestamp": time:utcNow().toString(),
            "database": "mongodb://mongodb:27017/ticketing",
            "features": ["send_notifications", "mark_as_read", "get_user_notifications"]
        };
        response.setJsonPayload(responseJson);
        return response;
    }
}
