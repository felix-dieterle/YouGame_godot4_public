#!/bin/bash

# Test runner script for YouGame Godot 4 project
# This script runs automated tests

set -e

echo "=== YouGame Test Runner ==="

# Configuration
PROJECT_PATH="."
TEST_SCENE="res://tests/test_scene.tscn"

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

# Run tests
echo "Running tests..."
$GODOT_CMD --headless --path "$PROJECT_PATH" "$TEST_SCENE"

if [ $? -eq 0 ]; then
    echo "=== Tests Completed ==="
else
    echo "=== Tests Failed ==="
    exit 1
fi
