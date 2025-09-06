#!/bin/bash

# Build script that enables network connections
echo "🔧 Building Stack with network access enabled..."

xcodebuild -project Stack.xcodeproj \
    -scheme Stack \
    -configuration Debug \
    ENABLE_OUTGOING_NETWORK_CONNECTIONS=YES \
    -destination 'platform=macOS' \
    build

if [ $? -eq 0 ]; then
    echo "✅ Build successful! Network access enabled."
    echo "🚀 You can now run the app and it should connect to Ollama."
else
    echo "❌ Build failed. Check the error messages above."
fi