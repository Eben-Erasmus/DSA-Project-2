# Smart Ticketing System - API Documentation

## Base URLs
- Passenger Service: `http://localhost:8081`
- Transport Service: `http://localhost:8082`
- Ticketing Service: `http://localhost:8083`
- Payment Service: `http://localhost:8084`
- Notification Service: `http://localhost:8085`
- Admin Service: `http://localhost:8086`

## Passenger Service API

### Register Passenger
```http
POST /passengers/register
Content-Type: application/json

{
  "email": "john.doe@example.com",
  "name": "John Doe",
  "phone": "+264123456789",
  "password": "password123"
}
```

### Login Passenger
```http
POST /passengers/login
Content-Type: application/json

{
  "email": "john.doe@example.com",
  "password": "password123"
}
```

### Get Passenger Details
```http
GET /passengers/{passengerId}
```

### Get Passenger Tickets
```http
GET /passengers/{passengerId}/tickets
```

## Transport Service API

### Get All Routes
```http
GET /transport/routes
```

### Get Trips for Route
```http
GET /transport/routes/{routeId}/trips
```

### Create Route (Admin)
```http
POST /transport/routes
Content-Type: application/json

{
  "name": "City Center - Airport",
  "routeType": "BUS",
  "stops": ["City Center", "Mall", "University", "Hospital", "Airport"]
}
```

### Create Trip (Admin)
```http
POST /transport/trips
Content-Type: application/json

{
  "routeId": "route-001",
  "departureTime": "2025-10-05T10:00:00Z",
  "arrivalTime": "2025-10-05T11:30:00Z",
  "price": 15.50,
  "availableSeats": 45
}
```

### Publish Schedule Update
```http
POST /transport/schedules/updates
Content-Type: application/json

{
  "tripId": "trip-001",
  "updateType": "DELAY",
  "newDepartureTime": "2025-10-05T10:15:00Z",
  "reason": "Traffic congestion"
}
```

## Ticketing Service API

### Purchase Ticket
```http
POST /tickets/purchase
Content-Type: application/json

{
  "passengerId": "passenger-001",
  "tripId": "trip-001",
  "ticketType": "SINGLE",
  "price": 15.50
}
```

### Validate Ticket
```http
PUT /tickets/{ticketId}/validate
Content-Type: application/json

{
  "ticketId": "ticket-001",
  "validatedBy": "validator-001"
}
```

### Get Ticket Details
```http
GET /tickets/{ticketId}
```

## Payment Service API

### Process Payment
```http
POST /payments/process
Content-Type: application/json

{
  "ticketId": "ticket-001",
  "passengerId": "passenger-001",
  "amount": 15.50,
  "paymentMethod": "CREDIT_CARD"
}
```

### Get Payment Status
```http
GET /payments/{paymentId}
```

## Notification Service API

### Get User Notifications
```http
GET /notifications/{userId}
```

### Send Notification (Internal)
```http
POST /notifications/send
Content-Type: application/json

{
  "userId": "passenger-001",
  "notificationType": "INFO",
  "title": "Trip Update",
  "message": "Your trip has been delayed by 15 minutes"
}
```

## Admin Service API

### Get Sales Report
```http
GET /admin/reports/sales
```

### Get Traffic Report
```http
GET /admin/reports/traffic
```

### Get Admin Dashboard
```http
GET /admin/dashboard
```

### Publish Service Disruption
```http
POST /admin/disruptions
Content-Type: application/json

{
  "routeId": "route-001",
  "disruptionType": "MAINTENANCE",
  "title": "Route Maintenance",
  "description": "Route will be closed for maintenance from 2AM to 6AM",
  "startTime": "2025-10-06T02:00:00Z",
  "endTime": "2025-10-06T06:00:00Z"
}
```

## Health Checks

All services provide health check endpoints:

```http
GET /{service}/health
```

Response:
```json
{
  "status": "healthy",
  "service": "service-name"
}
```

## Error Responses

Standard HTTP status codes are used:

- `200 OK` - Success
- `201 Created` - Resource created
- `400 Bad Request` - Invalid input
- `401 Unauthorized` - Authentication failed
- `404 Not Found` - Resource not found
- `409 Conflict` - Resource already exists
- `500 Internal Server Error` - Server error

## Sample Workflow

1. **Register and Login:**
   ```bash
   # Register
   curl -X POST http://localhost:8081/passengers/register \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","name":"Test User","phone":"+264123456789","password":"password123"}'
   
   # Login
   curl -X POST http://localhost:8081/passengers/login \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"password123"}'
   ```

2. **Browse Routes and Trips:**
   ```bash
   # Get routes
   curl http://localhost:8082/transport/routes
   
   # Get trips for a route
   curl http://localhost:8082/transport/routes/route-001/trips
   ```

3. **Purchase and Validate Ticket:**
   ```bash
   # Purchase ticket
   curl -X POST http://localhost:8083/tickets/purchase \
     -H "Content-Type: application/json" \
     -d '{"passengerId":"passenger-id","tripId":"trip-001","ticketType":"SINGLE","price":15.50}'
   
   # Validate ticket
   curl -X PUT http://localhost:8083/tickets/ticket-id/validate \
     -H "Content-Type: application/json" \
     -d '{"ticketId":"ticket-id","validatedBy":"validator-001"}'
   ```

4. **Check Notifications:**
   ```bash
   curl http://localhost:8085/notifications/passenger-id
   ```

## Event Messages

The system uses Kafka for event-driven communication. Here are sample event formats:

### Passenger Events
```json
{
  "eventType": "PASSENGER_REGISTERED",
  "data": {
    "passengerId": "passenger-001",
    "email": "test@example.com",
    "name": "Test User"
  },
  "timestamp": "2025-10-05T10:00:00Z"
}
```

### Ticket Events
```json
{
  "eventType": "TICKET_VALIDATED",
  "data": {
    "ticketId": "ticket-001",
    "passengerId": "passenger-001",
    "tripId": "trip-001",
    "validatedBy": "validator-001",
    "validationTime": "2025-10-05T10:00:00Z"
  },
  "timestamp": "2025-10-05T10:00:00Z"
}
```

### Payment Events
```json
{
  "eventType": "PAYMENT_PROCESSED",
  "data": {
    "paymentId": "payment-001",
    "ticketId": "ticket-001",
    "status": "COMPLETED",
    "amount": 15.50
  },
  "timestamp": "2025-10-05T10:00:00Z"
}
```
