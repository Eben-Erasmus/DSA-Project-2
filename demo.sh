#!/bin/bash

echo "=== Smart Ticketing System - Simple Demo ==="
echo ""

# Step 1: Test Docker
echo "Step 1: Testing Docker..."
if docker info > /dev/null 2>&1; then
    echo "✅ Docker is running"
    
    # Try with docker compose
    echo "Starting system with Docker Compose..."
    docker compose up -d --remove-orphans > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "✅ Docker Compose started successfully"
        echo "🌐 Access points:"
        echo "   - Kafka UI: http://localhost:8080"
        echo "   - Services: http://localhost:8081-8086"
        echo ""
        echo "Wait 30 seconds for services to start, then run:"
        echo "   ./test-apis.sh"
        exit 0
    else
        echo "❌ Docker Compose failed, trying alternative..."
    fi
else
    echo "❌ Docker is not running or accessible"
    echo ""
    echo "💡 To fix Docker issues:"
    echo "   1. Restart Docker Desktop from your applications"
    echo "   2. OR run: sudo systemctl restart docker"
    echo "   3. OR run: sudo service docker restart"
fi

echo ""
echo "Step 2: Testing individual Ballerina service..."

# Test if we can run a single service
cd services/passenger-service

echo "Building passenger service..."
if bal build > /dev/null 2>&1; then
    echo "✅ Passenger service builds successfully"
    
    echo "Starting passenger service on port 8081..."
    echo "🚀 Starting service... (Press Ctrl+C to stop)"
    echo ""
    
    # Start the service
    bal run &
    SERVICE_PID=$!
    
    # Wait for service to start
    sleep 5
    
    # Test the service
    echo "Testing passenger service..."
    
    # Test health endpoint
    HEALTH_RESPONSE=$(curl -s http://localhost:8081/health 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "✅ Health check: $HEALTH_RESPONSE"
        
        # Test registration
        echo "Testing passenger registration..."
        REG_RESPONSE=$(curl -s -X POST http://localhost:8081/passengers/register \
          -H "Content-Type: application/json" \
          -d '{
            "email": "test@example.com",
            "name": "Test User",
            "phone": "+264123456789",
            "password": "password123"
          }' 2>/dev/null)
        
        if [ $? -eq 0 ]; then
            echo "✅ Registration test successful"
            
            # Test login
            echo "Testing passenger login..."
            LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8081/passengers/login \
              -H "Content-Type: application/json" \
              -d '{
                "email": "test@example.com",
                "password": "password123"
              }' 2>/dev/null)
            
            if [ $? -eq 0 ]; then
                echo "✅ Login test successful"
                echo "📊 Login response: $LOGIN_RESPONSE"
                
                # Test get all passengers
                ALL_PASSENGERS=$(curl -s http://localhost:8081/passengers 2>/dev/null)
                echo "📋 All passengers: $ALL_PASSENGERS"
                
                echo ""
                echo "🎉 SUCCESS! The passenger service is working correctly!"
                echo ""
                echo "🌐 You can now test the service at: http://localhost:8081"
                echo ""
                echo "📝 Available endpoints:"
                echo "   POST /passengers/register - Register new passenger"
                echo "   POST /passengers/login - Login passenger"
                echo "   GET /passengers/{id} - Get passenger details"
                echo "   GET /passengers - Get all passengers"
                echo "   GET /health - Health check"
                echo ""
                echo "🛑 To stop the service, press Ctrl+C or run: kill $SERVICE_PID"
                
                # Keep service running
                wait $SERVICE_PID
                
            else
                echo "❌ Login test failed"
            fi
        else
            echo "❌ Registration test failed"
        fi
    else
        echo "❌ Service health check failed"
        kill $SERVICE_PID 2>/dev/null
    fi
else
    echo "❌ Passenger service build failed"
    echo "Please check the compilation errors above"
fi
