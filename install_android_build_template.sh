#!/bin/bash
# Install Android Build Template for Godot 4.3.0
# This script installs the Android build template needed for gradle_build exports

set -e

echo "=== Installing Android Build Template ==="

GODOT_VERSION="4.3.0.stable"
ANDROID_BUILD_DIR="./android/build"

# Check if running from repository root
if [ ! -f "project.godot" ]; then
    echo "Error: Must run from repository root"
    exit 1
fi

# Try to find the export templates in various possible locations
POSSIBLE_TEMPLATE_DIRS=(
    "$HOME/.local/share/godot/export_templates/$GODOT_VERSION"
    "$HOME/.local/share/godot/export_templates/4.3.0"
    "$HOME/.local/share/godot/templates/$GODOT_VERSION"
    "$HOME/.local/share/godot/templates/4.3.0"
    "/home/runner/.local/share/godot/export_templates/$GODOT_VERSION"
    "/home/runner/.local/share/godot/export_templates/4.3.0"
)

TEMPLATES_DIR=""
ANDROID_SOURCE_ZIP=""

# Find the templates directory
for dir in "${POSSIBLE_TEMPLATE_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        if [ -f "$dir/android_source.zip" ]; then
            TEMPLATES_DIR="$dir"
            ANDROID_SOURCE_ZIP="$dir/android_source.zip"
            echo "Found Godot export templates at: $TEMPLATES_DIR"
            break
        fi
    fi
done

# If not found in standard locations, try to find it using find command
if [ -z "$ANDROID_SOURCE_ZIP" ]; then
    echo "Templates not found in standard locations, searching..."
    FOUND_ZIP=$(find "$HOME/.local/share/godot" -name "android_source.zip" 2>/dev/null | head -n 1)
    if [ -n "$FOUND_ZIP" ]; then
        ANDROID_SOURCE_ZIP="$FOUND_ZIP"
        TEMPLATES_DIR=$(dirname "$FOUND_ZIP")
        echo "Found android_source.zip at: $ANDROID_SOURCE_ZIP"
    fi
fi

# Final check if we found the templates
if [ -z "$ANDROID_SOURCE_ZIP" ] || [ ! -f "$ANDROID_SOURCE_ZIP" ]; then
    echo "Error: Could not find android_source.zip in any known location"
    echo "Searched locations:"
    for dir in "${POSSIBLE_TEMPLATE_DIRS[@]}"; do
        echo "  - $dir"
    done
    echo ""
    echo "Please ensure Godot 4.3.0 export templates are installed"
    exit 1
fi

# Create android/build directory
mkdir -p "$ANDROID_BUILD_DIR"

# Extract android_source.zip to android/build
echo "Extracting Android build template..."
if ! unzip -q "$ANDROID_SOURCE_ZIP" -d "$ANDROID_BUILD_DIR"; then
    echo "Error: Failed to extract android_source.zip"
    echo "Source: $ANDROID_SOURCE_ZIP"
    echo "Destination: $ANDROID_BUILD_DIR"
    exit 1
fi

# Verify extraction
if [ -f "$ANDROID_BUILD_DIR/build.gradle" ]; then
    echo "✓ Android build template installed successfully!"
    echo "Location: $ANDROID_BUILD_DIR"
    echo ""
    echo "You can now build APKs with gradle_build=true"
    echo "The widget-enabled APK will now work properly."
else
    echo "Error: Build template extraction completed but expected files not found"
    echo "Please check $ANDROID_BUILD_DIR for contents"
    ls -la "$ANDROID_BUILD_DIR" || true
    exit 1
fi

echo "=== Installation Complete ==="
