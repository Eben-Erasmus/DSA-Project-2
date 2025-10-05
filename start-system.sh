#!/bin/bash

# Build and run all services

echo "Building and starting Smart Ticketing System..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Docker is not running. Please start Docker first."
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "docker-compose is not installed. Please install docker-compose first."
    exit 1
fi

# Build and start all services
echo "Building and starting all services with Docker Compose..."
docker-compose up --build -d

echo "Waiting for services to be ready..."
sleep 30

# Check service health
echo "Checking service health..."

services=("passenger-service:8081" "transport-service:8082" "ticketing-service:8083" "payment-service:8084" "notification-service:8085" "admin-service:8086")

for service in "${services[@]}"; do
    service_name=$(echo $service | cut -d':' -f1)
    port=$(echo $service | cut -d':' -f2)
    
    echo -n "Checking $service_name on port $port... "
    
    if curl -s http://localhost:$port/health > /dev/null; then
        echo "✓ Healthy"
    else
        echo "✗ Not responding"
    fi
done

echo ""
echo "Smart Ticketing System is up and running!"
echo ""
echo "Service URLs:"
echo "  Passenger Service: http://localhost:8081"
echo "  Transport Service: http://localhost:8082"
echo "  Ticketing Service: http://localhost:8083"
echo "  Payment Service:   http://localhost:8084"
echo "  Notification Service: http://localhost:8085"
echo "  Admin Service:     http://localhost:8086"
echo ""
echo "Infrastructure:"
echo "  Kafka UI:          http://localhost:8080"
echo "  MongoDB:           mongodb://localhost:27017"
echo ""
echo "To stop all services, run: docker-compose down"
