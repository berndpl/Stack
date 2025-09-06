#!/bin/bash

# Build script for iOS Simulator with network access
echo "🔧 Building Stack for iOS Simulator with network access enabled..."

xcodebuild -project Stack.xcodeproj \
    -scheme Stack \
    -configuration Debug \
    ENABLE_OUTGOING_NETWORK_CONNECTIONS=YES \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    build

if [ $? -eq 0 ]; then
    echo "✅ Build successful! Network access enabled for simulator."
    echo "🚀 You can now run the app in the simulator and it should connect to Ollama."
    echo "📱 To run: xcrun simctl install booted /path/to/Stack.app && xcrun simctl launch booted de.plontsch.Stack"
else
    echo "❌ Build failed. Check the error messages above."
fi