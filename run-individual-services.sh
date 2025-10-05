#!/bin/bash

# Run individual Ballerina services for testing
echo "Starting services individually with Ballerina..."

# Check if Ballerina is installed
if ! command -v bal &> /dev/null; then
    echo "Ballerina is not installed. Please install Ballerina first."
    echo "Visit: https://ballerina.io/downloads/"
    exit 1
fi

# Start MongoDB and Kafka using Docker first
echo "Starting MongoDB and Kafka..."
docker run -d --name mongodb -p 27017:27017 -e MONGO_INITDB_ROOT_USERNAME=admin -e MONGO_INITDB_ROOT_PASSWORD=password mongo:6.0

docker run -d --name zookeeper -p 2181:2181 confluentinc/cp-zookeeper:7.4.0 -e ZOOKEEPER_CLIENT_PORT=2181 -e ZOOKEEPER_TICK_TIME=2000

docker run -d --name kafka -p 9092:9092 --link zookeeper -e KAFKA_BROKER_ID=1 -e KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 confluentinc/cp-kafka:7.4.0

echo "Waiting for infrastructure to start..."
sleep 10

# Start services one by one
echo "Starting Passenger Service..."
cd services/passenger-service && bal run &
cd ../..

echo "Starting Transport Service..."
cd services/transport-service && bal run &
cd ../..

echo "Starting Ticketing Service..."
cd services/ticketing-service && bal run &
cd ../..

echo "Starting Payment Service..."
cd services/payment-service && bal run &
cd ../..

echo "Starting Notification Service..."
cd services/notification-service && bal run &
cd ../..

echo "Starting Admin Service..."
cd services/admin-service && bal run &
cd ../..

echo "All services started! Wait 30 seconds for initialization..."
sleep 30

echo "Testing services..."
./test-apis.sh
