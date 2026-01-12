# Bug Fixes: Version Display, Navigation Controls, and Menu Functionality

## Date
2026-01-12

## Issues Fixed

### 1. Version Not Displayed on Mobile
**Problem:** The game version (configured in project.godot as 1.0.16) was not visible to users, especially on mobile devices.

**Solution:** Added a permanent version label to the debug overlay system that displays in the bottom-right corner of the screen.

**Changes:**
- `scripts/debug_log_overlay.gd`:
  - Added `version_label: Label` variable
  - Created `_create_version_label()` function to display version in bottom-right corner
  - Version is now always visible and also logged at startup
  - Format: "Version: v1.0.16" (uses value from project.godot)

**How to Verify:**
1. Launch the game on any device
2. Look at the bottom-right corner of the screen
3. You should see "Version: v1.0.16" displayed
4. Open the debug log (📋 button) to see version logged at startup

---

### 2. Inverted Joystick Navigation
**Problem:** Navigation with the mobile joystick was inverted. When moving the joystick up (forward), the controls felt wrong because the input Y-axis wasn't properly mapped to the game's 3D coordinate system.

**Root Cause:** The documented fix to negate the Y-axis (from FIRST_PERSON_MOVEMENT_FIX.md) was never actually applied to the code. The input_dir.y value was being used directly instead of being negated.

**Solution:** Applied the Y-axis negation to both first-person and third-person movement modes.

**Changes:**
- `scripts/player.gd`:
  - Line 93: Changed `Vector3(input_dir.x, 0, input_dir.y)` to `Vector3(input_dir.x, 0, -input_dir.y)` for first-person
  - Line 97: Changed `Vector3(input_dir.x, 0, input_dir.y)` to `Vector3(input_dir.x, 0, -input_dir.y)` for third-person
  - Updated comments to explain the negation

**Technical Explanation:**
- Input system uses screen coordinates where Y-axis points down (standard UI)
- Pushing joystick "up" gives negative Y value
- Game's 3D system uses +Z as forward direction
- Without negation: up input (negative Y) → negative Z → moves backward (wrong!)
- With negation: up input (negative Y) → positive Z → moves forward (correct!)

**How to Verify:**
1. Launch the game on a mobile device or use virtual joystick
2. Push the joystick upward
3. The character should move forward (in the direction it's facing)
4. Switch to first-person mode (V key or menu button)
5. Push the joystick upward again
6. The view should move forward in the direction you're looking
7. The controls should feel natural in both modes

---

### 3. Non-Functional Mobile Controls Menu
**Problem:** The hamburger menu button (☰) in the top-left corner opened a settings panel, but the first-person toggle button and volume slider inside it were not functional. However, the centered pause menu (accessed via ESC or pause → settings) worked perfectly.

**Solution:** Instead of fixing the broken mobile controls settings panel, simplified the hamburger button to directly open the working pause menu. This is the minimal change that provides users with fully functional settings.

**Changes:**
- `scripts/mobile_controls.gd`:
  - Modified `_on_menu_button_pressed()` function
  - Removed code that toggled the local settings panel
  - Added code to open the pause menu via `get_tree().get_first_node_in_group("PauseMenu")`
  - The pause menu has all the same functionality (first-person toggle, volume control, pause) and it works correctly

**How to Verify:**
1. Launch the game on mobile or desktop
2. Click the hamburger menu button (☰) in the top-left corner
3. The pause menu should open (centered on screen)
4. Test the settings:
   - Toggle first-person view - should work
   - Adjust master volume - should work
   - Resume or quit game - should work
5. All functionality should work as expected

---

## Files Modified
1. `scripts/debug_log_overlay.gd` - Added version display
2. `scripts/player.gd` - Fixed joystick navigation with Y-axis negation
3. `scripts/mobile_controls.gd` - Simplified menu button to open pause menu

## Testing Recommendations
1. Test on Android device to verify:
   - Version is visible in bottom-right corner
   - Joystick controls work correctly (up = forward)
   - Menu button opens working pause menu
2. Test both first-person and third-person modes
3. Verify volume control and camera toggle work in pause menu

## Impact
These are minimal, surgical changes that fix the reported issues without affecting other game systems. The changes are backward-compatible and don't introduce new dependencies.
