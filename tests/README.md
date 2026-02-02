# YouGame Test Suite

This directory contains automated tests for the YouGame Godot 4 project.

## Quick Links

- **[Testing Guide](../docs/TESTING_GUIDE.md)** - Complete guide for writing and running tests
- **[Test Strategy](../docs/TEST_STRATEGY.md)** - Overall testing strategy and coverage goals

## Test Files

### Unit Tests
- `test_chunk.gd` / `test_scene_chunk.tscn` - Tests for chunk generation (seed reproducibility, walkability, lake generation)
- `test_narrative_markers.gd` / `test_scene_narrative_markers.tscn` - Tests for narrative system markers
- `test_clusters.gd` / `test_scene_clusters.tscn` - Tests for cluster system
- `test_mobile_controls.gd` / `test_scene_mobile_controls.tscn` - Tests for mobile controls, particularly view control joystick visibility
  - **Important**: This test creates MobileControls programmatically and must configure it with proper anchors (PRESET_FULL_RECT) to match the main.tscn scene configuration. Without these anchors, the control has zero size and joystick elements won't be visible or positioned correctly.

### Visual Tests (with Screenshot Capture)
- `test_visual_example.gd` / `test_scene_visual_example.tscn` - Example test demonstrating screenshot capture
- `test_path_visual.gd` / `test_scene_path_visual.tscn` - Visual test for path rendering across chunks with multiple camera angles

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

## Troubleshooting

### Mobile Controls Joystick Not Visible in Tests

If you're creating a `MobileControls` instance programmatically in tests and the joystick elements are not visible or positioned correctly, ensure you configure the control with proper anchors before adding it to the scene tree:

```gdscript
mobile_controls.set_anchors_preset(Control.PRESET_FULL_RECT)
mobile_controls.anchor_right = 1.0
mobile_controls.anchor_bottom = 1.0
mobile_controls.grow_horizontal = Control.GROW_DIRECTION_BOTH
mobile_controls.grow_vertical = Control.GROW_DIRECTION_BOTH
mobile_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
add_child(mobile_controls)
```

This configuration matches how MobileControls is set up in `main.tscn` and ensures the control fills the entire viewport, which is necessary for proper joystick positioning.
