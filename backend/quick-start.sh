#!/bin/bash

echo "🚀 Electricity Bill App Backend - Quick Start"
echo "============================================="

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "❌ Node.js version 18+ is required. Current version: $(node -v)"
    exit 1
fi

echo "✅ Node.js version: $(node -v)"

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed. Please install npm first."
    exit 1
fi

echo "✅ npm version: $(npm -v)"

# Install dependencies
echo ""
echo "📦 Installing dependencies..."
npm install

if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi

echo "✅ Dependencies installed successfully"

# Create necessary directories
echo ""
echo "📁 Creating directories..."
mkdir -p logs uploads src/templates/emails

# Check if .env file exists
if [ ! -f .env ]; then
    echo ""
    echo "⚙️  Setting up environment variables..."
    echo "Please run the setup script to configure your environment:"
    echo "node setup.js"
    echo ""
    echo "Or manually create a .env file based on env.example"
else
    echo "✅ Environment file (.env) already exists"
fi

# Check if MongoDB is running (optional)
echo ""
echo "🔍 Checking MongoDB connection..."
if command -v mongosh &> /dev/null; then
    if mongosh --eval "db.runCommand('ping')" &> /dev/null; then
        echo "✅ MongoDB is running"
    else
        echo "⚠️  MongoDB is not running. Please start MongoDB before running the app."
    fi
else
    echo "⚠️  MongoDB client not found. Please ensure MongoDB is installed and running."
fi

echo ""
echo "🎉 Setup completed!"
echo ""
echo "Next steps:"
echo "1. Configure your .env file with your API keys and settings"
echo "2. Start the development server: npm run dev"
echo "3. Test the API: curl http://localhost:3000/health"
echo ""
echo "For more information, see README.md and BACKEND_IMPLEMENTATION_GUIDE.md" 