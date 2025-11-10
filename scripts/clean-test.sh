#!/bin/bash

set -e  # Exit on error

echo "🧹 PII Management System - Clean Installation Test"
echo "=================================================="
echo ""

echo "Step 1: Stopping existing containers..."
docker compose down

echo ""
echo "Step 2: Removing volumes (this deletes all data)..."
docker compose down -v

echo ""
echo "Step 3: Removing images to force rebuild..."
docker rmi $(docker images -q 'pii-management-system-*') 2>/dev/null || echo "No images to remove"

echo ""
echo "Step 4: Cleaning up Docker system..."
docker system prune -f

echo ""
echo "Step 5: Checking .env file..."
if [ ! -f .env ]; then
    echo "⚠️  .env not found! Creating from .env.example..."
    cp .env.example .env
    echo "✓ Created .env from .env.example"
else
    echo "✓ .env file exists"
fi

echo ""
echo "Step 6: Verifying db/init-db.sql exists..."
if [ ! -f db/init-db.sql ]; then
    echo "⚠️  db/init-db.sql not found! Creating..."
    mkdir -p db
    cat > db/init-db.sql << 'SQL'
-- PostgreSQL initialization script
-- Note: No extensions needed for this application
SQL
    echo "✓ Created db/init-db.sql"
else
    echo "✓ db/init-db.sql exists"
fi

echo ""
echo "Step 7: Building and starting all services..."
echo "(This will take a few minutes on first run...)"
echo ""
docker compose up --build -d

echo ""
echo "Step 8: Waiting for services to start (30 seconds)..."
for i in {30..1}; do
    printf "\r⏳ Waiting... %2d seconds" $i
    sleep 1
done
echo ""

echo ""
echo "Step 9: Checking service status..."
docker compose ps

echo ""
echo "Step 10: Checking service health..."
echo ""

# Check PostgreSQL
if docker compose ps db | grep -q "healthy"; then
    echo "✓ PostgreSQL: Healthy"
else
    echo "❌ PostgreSQL: Not healthy"
fi

# Check Rails
if docker compose ps rails-api | grep -q "healthy"; then
    echo "✓ Rails API: Healthy"
else
    echo "⚠️  Rails API: Not healthy yet (may need more time)"
fi

# Check Java
if docker compose ps java-service | grep -q "healthy"; then
    echo "✓ Java Service: Healthy"
else
    echo "⚠️  Java Service: Not healthy yet (may need more time)"
fi

# Check React
if docker compose ps react-frontend | grep -q "Up"; then
    echo "✓ React Frontend: Running"
else
    echo "⚠️  React Frontend: Not running"
fi

echo ""
echo "=================================================="
echo "🎉 Setup Complete!"
echo ""
echo "Access the application:"
echo "  - React Frontend: http://localhost:5173"
echo "  - Rails API:      http://localhost:3000/up"
echo "  - Java Service:   http://localhost:8080/actuator/health"
echo ""
echo "To view logs:"
echo "  docker compose logs -f"
echo ""
echo "To stop:"
echo "  docker compose down"
echo "=================================================="
