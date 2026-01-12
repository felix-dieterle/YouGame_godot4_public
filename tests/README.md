# YouGame Test Suite

This directory contains automated tests for the YouGame Godot 4 project.

## Test Files

### Unit Tests
- `test_chunk.gd` / `test_scene_chunk.tscn` - Tests for chunk generation (seed reproducibility, walkability, lake generation)
- `test_narrative_markers.gd` / `test_scene_narrative_markers.tscn` - Tests for narrative system markers
- `test_clusters.gd` / `test_scene_clusters.tscn` - Tests for cluster system

### Visual Tests (with Screenshot Capture)
- `test_visual_example.gd` / `test_scene_visual_example.tscn` - Example test demonstrating screenshot capture

## Screenshot Functionality

### Overview
Tests can now capture screenshots that are automatically uploaded as artifacts in PR checks. This is useful for:
- Visual verification of new UI elements
- Demonstrating new features
- Debugging visual issues
- Creating visual documentation

### Quick Start

To add screenshots to a test:

```gdscript
extends Node

const ScreenshotHelper = preload("res://tests/screenshot_helper.gd")

func _ready():
    # Your test setup
    await create_visual_scene()
    get_tree().quit()

func create_visual_scene():
    # Wait for rendering
    await ScreenshotHelper.wait_for_render(5)
    
    # Capture screenshot
    ScreenshotHelper.capture_screenshot("my_test", "description")
```

### Screenshot Helper API

**`ScreenshotHelper.capture_screenshot(scene_name: String, description: String = "")`**
- Captures the current viewport as a PNG
- Saves to Godot's user data directory
- Returns the filesystem path
- Automatically includes in CI artifacts

**`ScreenshotHelper.wait_for_render(frames: int = 3)`**
- Waits for specified number of frames
- Ensures scene is fully rendered before screenshot
- Use before capturing screenshots

## Running Tests

### Locally
```bash
./tests/run_tests.sh
```

Screenshots will be collected in `./test_screenshots/` directory.

### In CI
Tests run automatically on PRs and pushes. Screenshots are uploaded as artifacts named `test-screenshots`.

## Adding New Tests

1. Create test script in `tests/test_*.gd`
2. Create test scene in `tests/test_scene_*.tscn`
3. Add test to `tests/run_tests.sh` array
4. (Optional) Use `ScreenshotHelper` for visual tests

See `test_visual_example.gd` for a complete example.

## Documentation

For detailed information about the screenshot system, see:
- [docs/TEST_SCREENSHOTS.md](../docs/TEST_SCREENSHOTS.md)
