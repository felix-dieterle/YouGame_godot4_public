#!/bin/bash
# Build script for SaveGameWidget Android plugin
# This builds the widget AAR file needed for APK export

set -e

echo "=== Building SaveGameWidget Android Plugin ==="

# Check if we're in the right directory
if [ ! -d "android/plugins/savegame_widget" ]; then
    echo "Error: Must run from repository root"
    exit 1
fi

cd android/plugins/savegame_widget

# Check if Gradle wrapper exists, if not create it
if [ ! -f "gradlew" ]; then
    echo "Creating Gradle wrapper..."
    gradle wrapper --gradle-version=8.1
fi

# Build the AAR
echo "Building AAR file..."
./gradlew assembleRelease

# Copy the AAR to the expected location
if [ -f "build/outputs/aar/savegame_widget-release.aar" ]; then
    cp build/outputs/aar/savegame_widget-release.aar savegame_widget.aar
    echo "✓ AAR file created: android/plugins/savegame_widget/savegame_widget.aar"
    echo "✓ Widget plugin is now ready for APK export"
else
    echo "Error: AAR file not found after build"
    exit 1
fi

echo "=== Build Complete ==="
