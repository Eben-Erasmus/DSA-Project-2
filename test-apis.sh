#!/bin/bash

# Test the ticketing system APIs

echo "Testing Smart Ticketing System APIs..."

BASE_URL="http://localhost"

# Test service health checks
echo "=== Health Checks ==="
for port in 8081 8082 8083 8084 8085 8086; do
    echo -n "Port $port: "
    curl -s $BASE_URL:$port/health | jq -r '.status // "error"'
done

echo ""
echo "=== Testing Passenger Service ==="

# Register a new passenger
echo "Registering new passenger..."
PASSENGER_RESPONSE=$(curl -s -X POST $BASE_URL:8081/passengers/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john.doe@example.com",
    "name": "John Doe", 
    "phone": "+264123456789",
    "password": "password123"
  }')
echo "Registration response: $PASSENGER_RESPONSE"

# Login passenger
echo "Logging in passenger..."
LOGIN_RESPONSE=$(curl -s -X POST $BASE_URL:8081/passengers/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john.doe@example.com",
    "password": "password123"
  }')
echo "Login response: $LOGIN_RESPONSE"

# Extract passenger ID
PASSENGER_ID=$(echo $LOGIN_RESPONSE | jq -r '.id // empty')
echo "Passenger ID: $PASSENGER_ID"

echo ""
echo "=== Testing Transport Service ==="

# Get all routes
echo "Getting all routes..."
curl -s $BASE_URL:8082/transport/routes | jq '.'

# Get trips for first route
echo "Getting trips for route-001..."
curl -s $BASE_URL:8082/transport/routes/route-001/trips | jq '.'

echo ""
echo "=== Testing Ticketing Service ==="

if [ ! -z "$PASSENGER_ID" ]; then
    # Purchase a ticket
    echo "Purchasing ticket..."
    TICKET_RESPONSE=$(curl -s -X POST $BASE_URL:8083/tickets/purchase \
      -H "Content-Type: application/json" \
      -d "{
        \"passengerId\": \"$PASSENGER_ID\",
        \"tripId\": \"trip-001\",
        \"ticketType\": \"SINGLE\",
        \"price\": 15.50
      }")
    echo "Ticket purchase response: $TICKET_RESPONSE"
fi

echo ""
echo "=== Testing Admin Service ==="

# Get sales report
echo "Getting sales report..."
curl -s $BASE_URL:8086/admin/reports/sales | jq '.'

# Get traffic report  
echo "Getting traffic report..."
curl -s $BASE_URL:8086/admin/reports/traffic | jq '.'

# Get dashboard
echo "Getting admin dashboard..."
curl -s $BASE_URL:8086/admin/dashboard | jq '.'

echo ""
echo "=== Testing Notification Service ==="

if [ ! -z "$PASSENGER_ID" ]; then
    # Get notifications for passenger
    echo "Getting notifications for passenger..."
    curl -s $BASE_URL:8085/notifications/$PASSENGER_ID | jq '.'
fi

echo ""
echo "API testing completed!"
