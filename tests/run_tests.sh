#!/bin/bash
# Test runner script that runs each test individually with timeout and reports results

TIMEOUT_SECONDS=60  # 1 minute per test
GODOT_CMD="godot --headless --path ."

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Screenshot directory setup
SCREENSHOT_OUTPUT_DIR="./test_screenshots"
mkdir -p "$SCREENSHOT_OUTPUT_DIR"

# Array of test scenes
tests=(
    "res://tests/test_scene_chunk.tscn|Chunk Tests"
    "res://tests/test_scene_narrative_markers.tscn|Narrative Markers Tests"
    "res://tests/test_scene_clusters.tscn|Clusters Tests"
    "res://tests/test_scene_visual_example.tscn|Visual Example Tests"
)

echo "========================================="
echo "Running YouGame Test Suite"
echo "========================================="
echo ""

failed_tests=()
passed_tests=()
timeout_tests=()

for test_info in "${tests[@]}"; do
    IFS='|' read -r test_scene test_name <<< "$test_info"
    
    echo "-----------------------------------"
    echo "Running: $test_name"
    echo "Scene: $test_scene"
    echo "-----------------------------------"
    
    # Run test with timeout
    timeout $TIMEOUT_SECONDS $GODOT_CMD "$test_scene" 2>&1
    exit_code=$?
    
    if [ $exit_code -eq 124 ]; then
        echo -e "${RED}✗ TIMEOUT${NC}: $test_name exceeded ${TIMEOUT_SECONDS}s limit"
        timeout_tests+=("$test_name")
    elif [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✓ PASSED${NC}: $test_name"
        passed_tests+=("$test_name")
    else
        echo -e "${RED}✗ FAILED${NC}: $test_name (exit code: $exit_code)"
        failed_tests+=("$test_name")
    fi
    echo ""
done

echo "========================================="
echo "Test Suite Summary"
echo "========================================="
echo -e "${GREEN}Passed: ${#passed_tests[@]}${NC}"
echo -e "${RED}Failed: ${#failed_tests[@]}${NC}"
echo -e "${YELLOW}Timeout: ${#timeout_tests[@]}${NC}"
echo ""

if [ ${#failed_tests[@]} -gt 0 ]; then
    echo "Failed tests:"
    for test in "${failed_tests[@]}"; do
        echo "  - $test"
    done
fi

if [ ${#timeout_tests[@]} -gt 0 ]; then
    echo "Tests that timed out:"
    for test in "${timeout_tests[@]}"; do
        echo "  - $test"
    done
fi

# Collect screenshots from Godot user directory
echo ""
echo "========================================="
echo "Collecting Screenshots"
echo "========================================="

# Godot user directory location (varies by OS)
if [ -d "$HOME/.local/share/godot/app_userdata/YouGame" ]; then
    GODOT_USER_DIR="$HOME/.local/share/godot/app_userdata/YouGame"
elif [ -d "$HOME/.local/share/godot/app_userdata/YouGame_godot4_public" ]; then
    GODOT_USER_DIR="$HOME/.local/share/godot/app_userdata/YouGame_godot4_public"
else
    # Try to find it
    GODOT_USER_DIR=$(find "$HOME/.local/share/godot/app_userdata" -maxdepth 1 -type d -name "*YouGame*" 2>/dev/null | head -n 1)
fi

if [ -n "$GODOT_USER_DIR" ] && [ -d "$GODOT_USER_DIR/test_screenshots" ]; then
    echo "Found screenshot directory: $GODOT_USER_DIR/test_screenshots"
    
    # Copy screenshots to output directory
    cp -v "$GODOT_USER_DIR/test_screenshots/"*.png "$SCREENSHOT_OUTPUT_DIR/" 2>/dev/null || true
    
    # Count screenshots
    SCREENSHOT_COUNT=$(ls -1 "$SCREENSHOT_OUTPUT_DIR/"*.png 2>/dev/null | wc -l)
    echo "Collected $SCREENSHOT_COUNT screenshot(s) to $SCREENSHOT_OUTPUT_DIR"
    
    # List screenshots
    if [ $SCREENSHOT_COUNT -gt 0 ]; then
        echo "Screenshots:"
        ls -lh "$SCREENSHOT_OUTPUT_DIR/"*.png
    fi
else
    echo "No screenshot directory found (this is normal for non-visual tests)"
fi

echo ""

# Exit with non-zero if any tests failed or timed out
if [ ${#failed_tests[@]} -gt 0 ] || [ ${#timeout_tests[@]} -gt 0 ]; then
    exit 1
fi

exit 0
