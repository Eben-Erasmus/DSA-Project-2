#!/bin/bash

# Simple test of individual service functionality
echo "=== Testing Ballerina Services Individually ==="

# Test if Ballerina is installed
if ! command -v bal &> /dev/null; then
    echo "❌ Ballerina is not installed."
    echo "Please install Ballerina from: https://ballerina.io/downloads/"
    exit 1
else
    echo "✅ Ballerina is installed: $(bal version)"
fi

echo ""
echo "=== Testing Service Compilation ==="

services=("passenger-service" "transport-service" "ticketing-service" "payment-service" "notification-service" "admin-service")

for service in "${services[@]}"; do
    echo -n "Testing $service compilation... "
    cd "services/$service"
    
    if bal build > /dev/null 2>&1; then
        echo "✅ Compiles successfully"
    else
        echo "❌ Compilation failed"
        echo "Error details:"
        bal build
    fi
    
    cd "../.."
done

echo ""
echo "=== Service Dependency Check ==="

# Check if all required dependencies are available
cd services/passenger-service
echo "Checking dependencies for passenger-service..."
bal deps

echo ""
echo "=== Manual Testing Instructions ==="
echo "1. Fix Docker connection issues:"
echo "   - Restart Docker Desktop from your applications"
echo "   - OR run: sudo systemctl restart docker"
echo "   - OR run: sudo service docker restart"
echo ""
echo "2. Once Docker is working, run:"
echo "   ./start-system.sh"
echo ""
echo "3. Test the APIs:"
echo "   ./test-apis.sh"
echo ""
echo "4. Access web interfaces:"
echo "   - Kafka UI: http://localhost:8080"
echo "   - Service APIs: http://localhost:8081-8086"
