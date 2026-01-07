#!/bin/bash

# Build script for YouGame Godot 4 project
# This script builds an APK for Android

set -e

echo "=== YouGame Build Script ==="

# Configuration
PROJECT_PATH="."
EXPORT_PRESET="Android"
OUTPUT_PATH="export/YouGame.apk"

# Check if Godot is available
if ! command -v godot &> /dev/null
then
    # Try godot4 or godot-headless
    if command -v godot4 &> /dev/null; then
        GODOT_CMD="godot4"
    elif command -v godot-headless &> /dev/null; then
        GODOT_CMD="godot-headless"
    else
        echo "ERROR: Godot not found. Please install Godot 4 or set up the godot command."
        exit 1
    fi
else
    GODOT_CMD="godot"
fi

echo "Using Godot: $GODOT_CMD"

# Create export directory
mkdir -p export

# Export the project
echo "Exporting project to APK..."
$GODOT_CMD --headless --export-release "$EXPORT_PRESET" "$OUTPUT_PATH"

if [ $? -eq 0 ]; then
    echo "=== Build Successful ==="
    echo "APK created at: $OUTPUT_PATH"
    ls -lh "$OUTPUT_PATH"
else
    echo "=== Build Failed ==="
    exit 1
fi
