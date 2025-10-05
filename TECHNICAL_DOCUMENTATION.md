# Smart Public Transport Ticketing System - Technical Documentation

## Architecture Overview

This project implements a distributed microservices-based smart ticketing system for public transport (buses and trains) using Ballerina, Kafka, MongoDB, and Docker.

### System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Passenger      │    │  Transport      │    │  Ticketing      │
│  Service        │    │  Service        │    │  Service        │
│  (Port 8081)    │    │  (Port 8082)    │    │  (Port 8083)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │     Kafka       │
                    │   Message Bus   │
                    └─────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Payment        │    │  Notification   │    │  Admin          │
│  Service        │    │  Service        │    │  Service        │
│  (Port 8084)    │    │  (Port 8085)    │    │  (Port 8086)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                 │
                    ┌─────────────────┐
                    │    MongoDB      │
                    │   Database      │
                    │  (Port 27017)   │
                    └─────────────────┘
```

## Service Details

### 1. Passenger Service (Port 8081)
**Responsibilities:**
- User registration and authentication
- Passenger profile management
- Password hashing and validation

**Key Endpoints:**
- `POST /passengers/register` - Register new passenger
- `POST /passengers/login` - Authenticate passenger
- `GET /passengers/{id}` - Get passenger details
- `GET /passengers/{id}/tickets` - Get passenger tickets

**Events Published:**
- `passenger.events` - Registration and login events

### 2. Transport Service (Port 8082)
**Responsibilities:**
- Route and trip management
- Schedule publishing
- Transport capacity management

**Key Endpoints:**
- `GET /transport/routes` - List all routes
- `GET /transport/routes/{id}/trips` - Get trips for route
- `POST /transport/routes` - Create new route (admin)
- `POST /transport/trips` - Create new trip (admin)
- `POST /transport/schedules/updates` - Publish schedule updates

**Events Published:**
- `schedule.updates` - Route and trip changes

### 3. Ticketing Service (Port 8083)
**Responsibilities:**
- Ticket creation and lifecycle management
- Ticket validation
- Integration with payment processing

**Key Endpoints:**
- `POST /tickets/purchase` - Purchase new ticket
- `PUT /tickets/{id}/validate` - Validate ticket
- `GET /tickets/{id}` - Get ticket details

**Events Published:**
- `ticket.requests` - New ticket purchase requests
- `ticket.events` - Ticket lifecycle events

**Events Consumed:**
- `payments.processed` - Payment confirmations

### 4. Payment Service (Port 8084)
**Responsibilities:**
- Payment processing simulation
- Payment status tracking
- Integration with ticketing system

**Key Endpoints:**
- `POST /payments/process` - Process payment
- `GET /payments/{id}` - Get payment status

**Events Published:**
- `payments.processed` - Payment completion events

**Events Consumed:**
- `ticket.requests` - Auto-process payments for tickets

### 5. Notification Service (Port 8085)
**Responsibilities:**
- Real-time notifications to users
- Event-driven notification generation
- Notification history management

**Key Endpoints:**
- `GET /notifications/{userId}` - Get user notifications
- `POST /notifications/send` - Send notification (internal)

**Events Consumed:**
- `schedule.updates` - Schedule change notifications
- `ticket.events` - Ticket-related notifications
- `passenger.events` - Welcome messages

### 6. Admin Service (Port 8086)
**Responsibilities:**
- System administration and reporting
- Sales and traffic analytics
- Service disruption management

**Key Endpoints:**
- `GET /admin/reports/sales` - Sales report
- `GET /admin/reports/traffic` - Traffic report
- `GET /admin/dashboard` - Admin dashboard
- `POST /admin/disruptions` - Publish service disruptions

## Data Models

### Passenger
```ballerina
type Passenger record {
    string id;
    string email;
    string name;
    string phone;
    string passwordHash;
    time:Utc createdAt;
};
```

### Route
```ballerina
type Route record {
    string id;
    string name;
    string routeType; // "BUS" | "TRAIN"
    string[] stops;
    boolean active;
    time:Utc createdAt;
};
```

### Trip
```ballerina
type Trip record {
    string id;
    string routeId;
    time:Utc departureTime;
    time:Utc arrivalTime;
    decimal price;
    int availableSeats;
    time:Utc createdAt;
};
```

### Ticket
```ballerina
type Ticket record {
    string id;
    string passengerId;
    string tripId;
    string ticketType; // "SINGLE" | "MULTI" | "PASS"
    string status; // "CREATED" | "PAID" | "VALIDATED" | "EXPIRED"
    decimal price;
    time:Utc purchaseTime;
    time:Utc? validationTime;
};
```

### Payment
```ballerina
type Payment record {
    string id;
    string ticketId;
    string passengerId;
    decimal amount;
    string status; // "PENDING" | "COMPLETED" | "FAILED"
    string paymentMethod;
    time:Utc createdAt;
    time:Utc? processedAt;
};
```

### Notification
```ballerina
type Notification record {
    string id;
    string userId;
    string notificationType;
    string title;
    string message;
    boolean read;
    time:Utc createdAt;
};
```

## Event-Driven Communication

### Kafka Topics

1. **passenger.events**
   - Passenger registration/login events
   - Consumed by: Notification Service

2. **ticket.requests**
   - New ticket purchase requests
   - Published by: Ticketing Service
   - Consumed by: Payment Service

3. **payments.processed**
   - Payment completion/failure events
   - Published by: Payment Service
   - Consumed by: Ticketing Service

4. **ticket.events**
   - Ticket lifecycle events (created, paid, validated)
   - Published by: Ticketing Service
   - Consumed by: Notification Service

5. **schedule.updates**
   - Route and trip schedule changes
   - Published by: Transport Service
   - Consumed by: Notification Service

6. **service.disruptions**
   - Service disruption announcements
   - Published by: Admin Service

## Database Schema

### MongoDB Collections

- **passengers** - User account information
- **routes** - Transport route definitions
- **trips** - Scheduled trips on routes
- **tickets** - Ticket purchases and validations
- **payments** - Payment transactions
- **notifications** - User notifications

### Indexes
- Unique indexes on `id` fields
- Performance indexes on commonly queried fields
- Compound indexes for complex queries

## Deployment

### Docker Services

- **zookeeper** - Kafka coordination
- **kafka** - Message broker
- **kafka-ui** - Kafka management interface
- **mongodb** - Primary database
- **passenger-service** - User management
- **transport-service** - Route/trip management
- **ticketing-service** - Ticket operations
- **payment-service** - Payment processing
- **notification-service** - User notifications
- **admin-service** - Administration

### Environment Variables

Each service uses these environment variables:
- `KAFKA_BOOTSTRAP_SERVERS` - Kafka connection string
- `MONGODB_URL` - MongoDB connection string

## Getting Started

### Prerequisites
- Docker and Docker Compose
- Git
- curl and jq (for testing)

### Quick Start

1. **Clone and start the system:**
   ```bash
   git clone <repository>
   cd DSA-Test
   ./start-system.sh
   ```

2. **Test the APIs:**
   ```bash
   ./test-apis.sh
   ```

3. **Stop the system:**
   ```bash
   ./stop-system.sh
   ```

### Manual Testing

1. **Register a passenger:**
   ```bash
   curl -X POST http://localhost:8081/passengers/register \
     -H "Content-Type: application/json" \
     -d '{
       "email": "test@example.com",
       "name": "Test User",
       "phone": "+264123456789",
       "password": "password123"
     }'
   ```

2. **View available routes:**
   ```bash
   curl http://localhost:8082/transport/routes
   ```

3. **Purchase a ticket:**
   ```bash
   curl -X POST http://localhost:8083/tickets/purchase \
     -H "Content-Type: application/json" \
     -d '{
       "passengerId": "<passenger_id>",
       "tripId": "trip-001",
       "ticketType": "SINGLE",
       "price": 15.50
     }'
   ```

## System Features

### Implemented Features

1. **Complete Microservices Architecture**
   - 6 independent services
   - Clear service boundaries
   - RESTful APIs

2. **Event-Driven Communication**
   - Kafka message broker
   - Asynchronous processing
   - Event sourcing patterns

3. **Data Persistence**
   - MongoDB database
   - Schema validation
   - Indexing for performance

4. **Containerization**
   - Docker containers for all services
   - Docker Compose orchestration
   - Production-ready setup

5. **Fault Tolerance**
   - Health check endpoints
   - Error handling
   - Service isolation

### Testing and Monitoring

- **Health Checks**: All services expose `/health` endpoints
- **API Testing**: Comprehensive test script included
- **Kafka Monitoring**: Kafka UI available at http://localhost:8080
- **Database Access**: MongoDB accessible at mongodb://localhost:27017

## Development Notes

### Code Quality
- The Ballerina code follows basic patterns and includes proper error handling
- Services are kept simple and focused on core functionality
- Event-driven patterns are implemented consistently

### Scalability
- Services can be scaled independently
- Kafka provides reliable message delivery
- MongoDB supports horizontal scaling

### Security
- Basic password hashing implemented
- Service isolation through containerization
- Environment-based configuration

## Future Enhancements

1. **Security Improvements**
   - JWT token authentication
   - API rate limiting
   - Encrypted communications

2. **Advanced Features**
   - Seat reservations
   - Real-time tracking
   - Mobile app integration

3. **Monitoring and Observability**
   - Prometheus metrics
   - Grafana dashboards
   - Distributed tracing

4. **Deployment**
   - Kubernetes manifests
   - CI/CD pipelines
   - Production hardening
