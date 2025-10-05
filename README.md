# Smart Public Transport Ticketing System

A distributed microservices-based ticketing system for buses and trains built with Ballerina.

## Architecture Overview

This system consists of 6 microservices:
1. **Passenger Service** - User registration, login, account management
2. **Transport Service** - Route and trip management, schedule updates
3. **Ticketing Service** - Ticket lifecycle management
4. **Payment Service** - Payment processing simulation
5. **Notification Service** - Real-time notifications
6. **Admin Service** - Administrative operations and reporting

## Technologies Used

- **Ballerina** - All microservices implementation
- **Apache Kafka** - Event-driven communication
- **MongoDB** - Data persistence
- **Docker & Docker Compose** - Containerization and orchestration

## Project Structure

```
.
├── services/
│   ├── passenger-service/
│   ├── transport-service/
│   ├── ticketing-service/
│   ├── payment-service/
│   ├── notification-service/
│   └── admin-service/
├── infrastructure/
│   ├── kafka/
│   ├── mongodb/
│   └── docker/
├── docker-compose.yml
└── README.md
```

## Kafka Topics

- `passenger.events` - Passenger registration/login events
- `ticket.requests` - Ticket purchase requests
- `payments.processed` - Payment confirmations
- `ticket.validated` - Ticket validation events
- `schedule.updates` - Route/trip schedule changes
- `notifications` - General notification events

## Getting Started

1. Ensure you have Docker and Docker Compose installed
2. Clone this repository
3. Run `docker-compose up` to start all services
4. Access the services via their respective ports

## API Endpoints

### Passenger Service (Port 8081)
- `POST /passengers/register` - Register new passenger
- `POST /passengers/login` - Login passenger
- `GET /passengers/{id}` - Get passenger details
- `GET /passengers/{id}/tickets` - Get passenger tickets

### Transport Service (Port 8082)
- `GET /routes` - Get all routes
- `GET /routes/{id}/trips` - Get trips for a route
- `POST /routes` - Create new route (admin)
- `POST /trips` - Create new trip (admin)

### Ticketing Service (Port 8083)
- `POST /tickets` - Purchase ticket
- `PUT /tickets/{id}/validate` - Validate ticket
- `GET /tickets/{id}` - Get ticket details

### Payment Service (Port 8084)
- `POST /payments` - Process payment
- `GET /payments/{id}` - Get payment status

### Notification Service (Port 8085)
- `GET /notifications/{userId}` - Get user notifications
- `POST /notifications` - Send notification (internal)

### Admin Service (Port 8086)
- `GET /admin/reports/sales` - Ticket sales reports
- `GET /admin/reports/traffic` - Passenger traffic reports
- `POST /admin/disruptions` - Publish service disruptions

## Data Models

### Passenger
```json
{
  "id": "string",
  "email": "string",
  "name": "string",
  "phone": "string",
  "createdAt": "timestamp"
}
```

### Route
```json
{
  "id": "string",
  "name": "string",
  "type": "BUS|TRAIN",
  "stops": ["string"],
  "active": "boolean"
}
```

### Trip
```json
{
  "id": "string",
  "routeId": "string",
  "departureTime": "timestamp",
  "arrivalTime": "timestamp",
  "price": "decimal",
  "availableSeats": "int"
}
```

### Ticket
```json
{
  "id": "string",
  "passengerId": "string",
  "tripId": "string",
  "type": "SINGLE|MULTI|PASS",
  "status": "CREATED|PAID|VALIDATED|EXPIRED",
  "price": "decimal",
  "purchaseTime": "timestamp",
  "validationTime": "timestamp"
}
```

## Development

Each service is a separate Ballerina package with its own configuration and dependencies.

To run services individually:
```bash
cd services/passenger-service
bal run
```

## Testing

Run tests for all services:
```bash
./run-tests.sh
```

## Monitoring

- Kafka messages can be monitored via Kafka UI at http://localhost:8080
- MongoDB can be accessed via MongoDB Compass at mongodb://localhost:27017
