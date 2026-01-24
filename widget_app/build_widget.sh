#!/bin/bash
# Build script for standalone widget APK

set -e

echo "========================================="
echo "Building YouGame Widget APK"
echo "========================================="

cd "$(dirname "$0")"

# Check if gradlew exists, if not create wrapper
if [ ! -f gradlew ]; then
    echo "Creating Gradle wrapper..."
    gradle wrapper --gradle-version 8.0
fi

echo "Building widget APK..."
./gradlew assembleDebug

if [ -f app/build/outputs/apk/debug/app-debug.apk ]; then
    echo "✓ Widget APK built successfully!"
    ls -lh app/build/outputs/apk/debug/app-debug.apk
    
    # Copy to release directory with descriptive name
    mkdir -p ../../release
    cp app/build/outputs/apk/debug/app-debug.apk ../../release/YouGame-Widget.apk
    echo "✓ Copied to release/YouGame-Widget.apk"
else
    echo "❌ Failed to build widget APK"
    exit 1
fi

echo "========================================="
echo "Widget Build Complete!"
echo "========================================="
