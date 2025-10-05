// MongoDB initialization script for ticketing system

// Switch to ticketing database
db = db.getSiblingDB('ticketing');

// Create collections with validation
db.createCollection("passengers", {
   validator: {
      $jsonSchema: {
         bsonType: "object",
         required: ["id", "email", "name", "phone", "passwordHash", "createdAt"],
         properties: {
            id: { bsonType: "string" },
            email: { bsonType: "string" },
            name: { bsonType: "string" },
            phone: { bsonType: "string" },
            passwordHash: { bsonType: "string" },
            createdAt: { bsonType: "date" }
         }
      }
   }
});

db.createCollection("routes", {
   validator: {
      $jsonSchema: {
         bsonType: "object",
         required: ["id", "name", "routeType", "stops", "active", "createdAt"],
         properties: {
            id: { bsonType: "string" },
            name: { bsonType: "string" },
            routeType: { bsonType: "string", enum: ["BUS", "TRAIN"] },
            stops: { bsonType: "array", items: { bsonType: "string" } },
            active: { bsonType: "bool" },
            createdAt: { bsonType: "date" }
         }
      }
   }
});

db.createCollection("trips", {
   validator: {
      $jsonSchema: {
         bsonType: "object",
         required: ["id", "routeId", "departureTime", "arrivalTime", "price", "availableSeats", "createdAt"],
         properties: {
            id: { bsonType: "string" },
            routeId: { bsonType: "string" },
            departureTime: { bsonType: "date" },
            arrivalTime: { bsonType: "date" },
            price: { bsonType: "decimal" },
            availableSeats: { bsonType: "int" },
            createdAt: { bsonType: "date" }
         }
      }
   }
});

db.createCollection("tickets", {
   validator: {
      $jsonSchema: {
         bsonType: "object",
         required: ["id", "passengerId", "tripId", "ticketType", "status", "price", "purchaseTime"],
         properties: {
            id: { bsonType: "string" },
            passengerId: { bsonType: "string" },
            tripId: { bsonType: "string" },
            ticketType: { bsonType: "string", enum: ["SINGLE", "MULTI", "PASS"] },
            status: { bsonType: "string", enum: ["CREATED", "PAID", "VALIDATED", "EXPIRED"] },
            price: { bsonType: "decimal" },
            purchaseTime: { bsonType: "date" },
            validationTime: { bsonType: ["date", "null"] }
         }
      }
   }
});

db.createCollection("payments", {
   validator: {
      $jsonSchema: {
         bsonType: "object",
         required: ["id", "ticketId", "passengerId", "amount", "status", "paymentMethod", "createdAt"],
         properties: {
            id: { bsonType: "string" },
            ticketId: { bsonType: "string" },
            passengerId: { bsonType: "string" },
            amount: { bsonType: "decimal" },
            status: { bsonType: "string", enum: ["PENDING", "COMPLETED", "FAILED"] },
            paymentMethod: { bsonType: "string" },
            createdAt: { bsonType: "date" },
            processedAt: { bsonType: ["date", "null"] }
         }
      }
   }
});

db.createCollection("notifications", {
   validator: {
      $jsonSchema: {
         bsonType: "object",
         required: ["id", "userId", "notificationType", "title", "message", "read", "createdAt"],
         properties: {
            id: { bsonType: "string" },
            userId: { bsonType: "string" },
            notificationType: { bsonType: "string" },
            title: { bsonType: "string" },
            message: { bsonType: "string" },
            read: { bsonType: "bool" },
            createdAt: { bsonType: "date" }
         }
      }
   }
});

// Create indexes for better performance
db.passengers.createIndex({ "email": 1 }, { unique: true });
db.passengers.createIndex({ "id": 1 }, { unique: true });

db.routes.createIndex({ "id": 1 }, { unique: true });
db.routes.createIndex({ "active": 1 });

db.trips.createIndex({ "id": 1 }, { unique: true });
db.trips.createIndex({ "routeId": 1 });
db.trips.createIndex({ "departureTime": 1 });

db.tickets.createIndex({ "id": 1 }, { unique: true });
db.tickets.createIndex({ "passengerId": 1 });
db.tickets.createIndex({ "tripId": 1 });
db.tickets.createIndex({ "status": 1 });

db.payments.createIndex({ "id": 1 }, { unique: true });
db.payments.createIndex({ "ticketId": 1 });
db.payments.createIndex({ "passengerId": 1 });

db.notifications.createIndex({ "id": 1 }, { unique: true });
db.notifications.createIndex({ "userId": 1 });
db.notifications.createIndex({ "createdAt": -1 });

print("Database initialized successfully!");

// Insert sample data
db.routes.insertMany([
   {
      id: "route-001",
      name: "City Center - Airport",
      routeType: "BUS",
      stops: ["City Center", "Mall", "University", "Hospital", "Airport"],
      active: true,
      createdAt: new Date()
   },
   {
      id: "route-002", 
      name: "North Station - South Terminal",
      routeType: "TRAIN",
      stops: ["North Station", "Central", "Industrial District", "South Terminal"],
      active: true,
      createdAt: new Date()
   },
   {
      id: "route-003",
      name: "Beach - Mountains",
      routeType: "BUS", 
      stops: ["Beach Resort", "Coastal Road", "City Center", "Hills", "Mountain View"],
      active: true,
      createdAt: new Date()
   }
]);

db.trips.insertMany([
   {
      id: "trip-001",
      routeId: "route-001",
      departureTime: new Date(Date.now() + 3600000), // 1 hour from now
      arrivalTime: new Date(Date.now() + 5400000),   // 1.5 hours from now
      price: NumberDecimal("15.50"),
      availableSeats: 45,
      createdAt: new Date()
   },
   {
      id: "trip-002",
      routeId: "route-002", 
      departureTime: new Date(Date.now() + 7200000), // 2 hours from now
      arrivalTime: new Date(Date.now() + 9000000),   // 2.5 hours from now
      price: NumberDecimal("22.00"),
      availableSeats: 120,
      createdAt: new Date()
   },
   {
      id: "trip-003",
      routeId: "route-003",
      departureTime: new Date(Date.now() + 10800000), // 3 hours from now  
      arrivalTime: new Date(Date.now() + 14400000),   // 4 hours from now
      price: NumberDecimal("18.75"),
      availableSeats: 38,
      createdAt: new Date()
   }
]);

print("Sample data inserted successfully!");
