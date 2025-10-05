#!/bin/bash

# Stop all services

echo "Stopping Smart Ticketing System..."

docker-compose down

echo "Cleaning up..."
docker-compose down --volumes --remove-orphans

echo "System stopped and cleaned up!"
