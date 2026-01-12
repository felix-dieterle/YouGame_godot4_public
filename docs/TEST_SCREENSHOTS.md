# Test Screenshot Functionality

## Overview

This implementation adds automatic screenshot capture functionality for test scenes during PR checks. Screenshots from newly added tests with visual elements can now be automatically captured and uploaded as artifacts in GitHub Actions.

## How It Works

### 1. Screenshot Helper (`tests/screenshot_helper.gd`)

A reusable utility script that provides screenshot capture functionality for any test:

- `init_screenshot_dir()` - Creates the screenshot directory in Godot's user data folder
- `capture_screenshot(scene_name, description)` - Captures and saves a screenshot
- `wait_for_render(frames)` - Waits for scene rendering to complete

### 2. Example Visual Test (`tests/test_visual_example.gd`)

A demonstration test showing how to integrate screenshot capture:

```gdscript
const ScreenshotHelper = preload("res://tests/screenshot_helper.gd")

func create_visual_scene():
    # Wait for rendering
    await ScreenshotHelper.wait_for_render(5)
    
    # Capture screenshot
    ScreenshotHelper.capture_screenshot("example_visual_test", "initial_state")
```

### 3. Test Runner Enhancement (`tests/run_tests.sh`)

The test runner now:
- Creates a `test_screenshots` output directory
- Runs the visual example test alongside existing tests
- Collects screenshots from Godot's user data directory after tests complete
- Copies screenshots to the output directory for CI access

### 4. GitHub Actions Integration (`.github/workflows/build.yml`)

Added a new step that:
- Runs after all tests complete (even if some tests fail)
- Uploads screenshots as GitHub Actions artifacts
- Makes screenshots available in the PR checks UI

## Usage

### For Test Developers

To add screenshot capture to a new or existing test:

1. **Import the screenshot helper:**
   ```gdscript
   const ScreenshotHelper = preload("res://tests/screenshot_helper.gd")
   ```

2. **Create a visual scene with 3D elements or UI:**
   ```gdscript
   func create_visual_scene():
       # Your scene setup code here
       # ... add nodes, create terrain, etc.
   ```

3. **Wait for rendering (important for getting complete visuals):**
   ```gdscript
   await ScreenshotHelper.wait_for_render(5)  # Wait 5 frames
   ```

4. **Capture screenshot with descriptive name:**
   ```gdscript
   ScreenshotHelper.capture_screenshot("my_test_name", "description")
   ```

5. **Add your test scene to the test runner** in `tests/run_tests.sh`:
   ```bash
   tests=(
       "res://tests/test_scene_chunk.tscn|Chunk Tests"
       # ... existing tests
       "res://tests/test_scene_my_new_feature.tscn|My New Feature Tests"
   )
   ```

### For Reviewers

Screenshots will be available in PR checks:

1. Go to the PR's "Checks" tab
2. Click on the "Run Tests" job
3. Scroll to "Artifacts" section
4. Download "test-screenshots" artifact
5. View the PNG files to see visual outputs from tests

## Example Use Cases

- **UI Element Tests**: Capture screenshots of new UI components
- **Terrain Generation**: Show examples of procedurally generated terrain
- **Visual Effects**: Demonstrate particle systems, lighting, or shaders
- **Layout Verification**: Confirm proper positioning of game elements
- **Before/After Comparisons**: Capture state changes in the game

## Screenshot Naming Convention

Screenshots are automatically named using the pattern:
```
{scene_name}_{description}.png
```

Example: `example_visual_test_initial_state.png`

## Technical Details

### Screenshot Storage

- **During Test Execution**: `~/.local/share/godot/app_userdata/{project_name}/test_screenshots/`
- **CI Output Directory**: `./test_screenshots/`
- **GitHub Artifact**: Available as `test-screenshots.zip`

### Limitations

- Screenshots are captured in headless mode (no actual GPU rendering)
- Only captures what's in the viewport at the time of capture
- Screenshots reflect the state after rendering, so wait for render completion

## Benefits

1. **Visual Verification**: Reviewers can see what new features look like
2. **Regression Detection**: Compare screenshots across commits
3. **Documentation**: Screenshots serve as visual documentation
4. **Debugging**: Help identify visual issues in CI environment
5. **Transparency**: Makes test outputs visible in PR review process

## Future Enhancements

Potential improvements:
- Add screenshot comparison with baseline images
- Generate HTML report with all screenshots
- Automatic visual regression testing
- Comment on PR with screenshot previews
