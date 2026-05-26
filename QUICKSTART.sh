#!/bin/bash
# CodeMania Quick Start Script
# Run this to verify your environment setup

echo "🔍 Checking CodeMania prerequisites..."
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker Desktop."
    exit 1
fi
echo "✓ Docker installed: $(docker --version)"

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose not found. Please install Docker Desktop."
    exit 1
fi
echo "✓ Docker Compose installed: $(docker-compose --version)"

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please install Node.js 18+"
    exit 1
fi
NODE_VERSION=$(node -v)
echo "✓ Node.js installed: $NODE_VERSION"

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter 3.13+"
    exit 1
fi
FLUTTER_VERSION=$(flutter --version | head -n 1)
echo "✓ Flutter installed: $FLUTTER_VERSION"

# Check psql
if ! command -v psql &> /dev/null; then
    echo "⚠ psql not found. You'll need it for database setup."
    echo "  Install: PostgreSQL client (or dbmate/similar)"
fi

echo ""
echo "📋 Starting infrastructure..."
echo ""

# Start Docker containers
docker-compose up -d

echo ""
echo "⏳ Waiting for services to be ready..."
sleep 5

# Check PostgreSQL
if docker-compose exec -T postgres pg_isready -U codemania &>/dev/null; then
    echo "✓ PostgreSQL ready"
else
    echo "⚠ PostgreSQL still starting..."
fi

# Check Redis
if docker-compose exec -T redis redis-cli ping &>/dev/null; then
    echo "✓ Redis ready"
else
    echo "⚠ Redis still starting..."
fi

# Check Piston
if curl -s http://localhost:2000/api/v2/runtimes > /dev/null 2>&1; then
    echo "✓ Piston API ready"
else
    echo "⚠ Piston still starting..."
fi

echo ""
echo "📦 Next steps:"
echo ""
echo "1️⃣  Initialize database:"
echo "   psql -U codemania -h localhost -d codemania -f schema.sql"
echo ""
echo "2️⃣  Place Firebase service account key:"
echo "   cp serviceAccountKey.json backend/"
echo ""
echo "3️⃣  Set up backend:"
echo "   cd backend"
echo "   cp .env.example .env"
echo "   npm install"
echo "   node index.js"
echo ""
echo "4️⃣  Set up Flutter (in new terminal):"
echo "   cd flutter_app"
echo "   flutter pub get"
echo "   flutter run -d chrome"
echo ""
echo "✨ Happy coding!"
