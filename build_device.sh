#!/bin/bash

# Build script for iOS Device with network access
echo "🔧 Building Stack for iOS Device with network access enabled..."

xcodebuild -project Stack.xcodeproj \
    -scheme Stack \
    -configuration Debug \
    ENABLE_OUTGOING_NETWORK_CONNECTIONS=YES \
    -destination 'generic/platform=iOS' \
    build

if [ $? -eq 0 ]; then
    echo "✅ Build successful! Network access enabled for device."
    echo "🚀 You can now run the app on your device and it should connect to Ollama."
    echo "📱 To install: Use Xcode to install and run on your connected device"
else
    echo "❌ Build failed. Check the error messages above."
fi