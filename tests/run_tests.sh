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

# Project name detection - try to extract from project.godot
PROJECT_NAME="YouGame"
if [ -f "project.godot" ]; then
    # Extract project name from config/name field (handles both quoted and unquoted values)
    EXTRACTED_NAME=$(grep -E '^config/name=' project.godot | sed -E 's/^config\/name="?([^"]*)"?$/\1/')
    if [ -n "$EXTRACTED_NAME" ]; then
        PROJECT_NAME="$EXTRACTED_NAME"
    fi
fi

# Array of test scenes
tests=(
    "res://tests/test_scene_chunk.tscn|Chunk Tests"
    "res://tests/test_scene_narrative_markers.tscn|Narrative Markers Tests"
    "res://tests/test_scene_clusters.tscn|Clusters Tests"
    "res://tests/test_scene_visual_example.tscn|Visual Example Tests"
    "res://tests/test_scene_mobile_controls.tscn|Mobile Controls Tests"
    "res://tests/test_scene_day_night_cycle.tscn|Day Night Cycle Tests"
    "res://tests/test_scene_path_visual.tscn|Path Visual Tests"
    "res://tests/test_scene_world_manager.tscn|World Manager Tests"
    "res://tests/test_scene_npc.tscn|NPC System Tests"
    "res://tests/test_scene_quest_hook_system.tscn|Quest Hook System Tests"
    "res://tests/test_scene_herb_system.tscn|Herb System Tests"
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
    # Filter out harmless rendering errors from headless mode
    timeout $TIMEOUT_SECONDS $GODOT_CMD "$test_scene" 2>&1 | grep -v "mesh_get_surface_count" | grep -v "Parameter \"m\" is null"
    exit_code=${PIPESTATUS[0]}
    
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

# Godot user directory location (varies by OS and project name)
GODOT_USER_DIR=""

# Try common project name variations
if [ -d "$HOME/.local/share/godot/app_userdata/$PROJECT_NAME" ]; then
    GODOT_USER_DIR="$HOME/.local/share/godot/app_userdata/$PROJECT_NAME"
else
    # Try to find any directory matching the project name pattern
    GODOT_USER_DIR=$(find "$HOME/.local/share/godot/app_userdata" -maxdepth 1 -type d -name "*$PROJECT_NAME*" 2>/dev/null | head -n 1)
fi

if [ -n "$GODOT_USER_DIR" ] && [ -d "$GODOT_USER_DIR/test_screenshots" ]; then
    echo "Found screenshot directory: $GODOT_USER_DIR/test_screenshots"
    
    # Copy screenshots to output directory using find for robustness
    find "$GODOT_USER_DIR/test_screenshots" -name "*.png" -type f -exec cp -v {} "$SCREENSHOT_OUTPUT_DIR/" \; 2>/dev/null || true
    
    # Count screenshots
    SCREENSHOT_COUNT=$(find "$SCREENSHOT_OUTPUT_DIR" -name "*.png" -type f 2>/dev/null | wc -l)
    echo "Collected $SCREENSHOT_COUNT screenshot(s) to $SCREENSHOT_OUTPUT_DIR"
    
    # List screenshots
    if [ $SCREENSHOT_COUNT -gt 0 ]; then
        echo "Screenshots:"
        ls -lh "$SCREENSHOT_OUTPUT_DIR/"*.png 2>/dev/null || true
    fi
else
    echo "No screenshot directory found (this is normal for non-visual tests)"
fi

echo ""

# Generate test results log for CI
echo "Generating test results log..."
cat > test_results.log <<EOF
## Summary

- ✅ Passed: ${#passed_tests[@]}
- ❌ Failed: ${#failed_tests[@]}
- ⏱️  Timeout: ${#timeout_tests[@]}
- 📊 Total: $((${#passed_tests[@]} + ${#failed_tests[@]} + ${#timeout_tests[@]}))

EOF

if [ ${#passed_tests[@]} -gt 0 ]; then
    echo "## Passed Tests" >> test_results.log
    echo "" >> test_results.log
    for test in "${passed_tests[@]}"; do
        echo "- ✅ $test" >> test_results.log
    done
    echo "" >> test_results.log
fi

if [ ${#failed_tests[@]} -gt 0 ]; then
    echo "## Failed Tests" >> test_results.log
    echo "" >> test_results.log
    for test in "${failed_tests[@]}"; do
        echo "- ❌ $test" >> test_results.log
    done
    echo "" >> test_results.log
fi

if [ ${#timeout_tests[@]} -gt 0 ]; then
    echo "## Timed Out Tests" >> test_results.log
    echo "" >> test_results.log
    for test in "${timeout_tests[@]}"; do
        echo "- ⏱️ $test" >> test_results.log
    done
fi

echo "Test results saved to test_results.log"

# Exit with non-zero if any tests failed or timed out
if [ ${#failed_tests[@]} -gt 0 ] || [ ${#timeout_tests[@]} -gt 0 ]; then
    exit 1
fi

exit 0
