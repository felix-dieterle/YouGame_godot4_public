#!/bin/bash
# Install Android Build Template for Godot 4.3.0
# This script installs the Android build template needed for gradle_build exports

set -e

echo "=== Installing Android Build Template ==="

GODOT_VERSION="4.3.0.stable"
TEMPLATES_DIR="$HOME/.local/share/godot/export_templates/$GODOT_VERSION"
ANDROID_SOURCE_ZIP="$TEMPLATES_DIR/android_source.zip"
ANDROID_BUILD_DIR="./android/build"

# Check if running from repository root
if [ ! -f "project.godot" ]; then
    echo "Error: Must run from repository root"
    exit 1
fi

# Check if Godot export templates are installed
if [ ! -d "$TEMPLATES_DIR" ]; then
    echo "Error: Godot export templates not found at $TEMPLATES_DIR"
    echo "Please install Godot 4.3.0 export templates first"
    echo ""
    echo "You can install templates by:"
    echo "1. Opening Godot Editor"
    echo "2. Going to Editor -> Manage Export Templates"
    echo "3. Downloading templates for version 4.3.0"
    exit 1
fi

echo "Found Godot export templates at: $TEMPLATES_DIR"

# Check if android_source.zip exists
if [ ! -f "$ANDROID_SOURCE_ZIP" ]; then
    echo "Error: android_source.zip not found in export templates"
    echo "Expected at: $ANDROID_SOURCE_ZIP"
    exit 1
fi

# Create android/build directory
mkdir -p "$ANDROID_BUILD_DIR"

# Extract android_source.zip to android/build
echo "Extracting Android build template..."
unzip -q "$ANDROID_SOURCE_ZIP" -d "$ANDROID_BUILD_DIR"

# Verify extraction
if [ -f "$ANDROID_BUILD_DIR/build.gradle" ]; then
    echo "✓ Android build template installed successfully!"
    echo "Location: $ANDROID_BUILD_DIR"
    echo ""
    echo "You can now build APKs with gradle_build=true"
    echo "The widget-enabled APK will now work properly."
else
    echo "Error: Build template extraction may have failed"
    echo "Please check $ANDROID_BUILD_DIR"
    exit 1
fi

echo "=== Installation Complete ==="
