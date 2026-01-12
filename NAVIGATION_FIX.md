# Navigation Fix: Left/Right Inversion

## Date
2026-01-12

## Issue Fixed
Joystick directions were inverted on the horizontal axis. When pushing the joystick right, the avatar moved left, and vice versa.

## Root Cause
This game uses an unusual "face-to-face" third-person camera setup where the camera looks at the player's face (not from behind). The camera is positioned at +Z looking back at the player at origin.

With this camera orientation:
- Player's right (+X direction) appears on the LEFT side of the screen
- Player's left (-X direction) appears on the RIGHT side of the screen

This creates a "mirror effect" where controls feel inverted without proper input transformation.

## Solution
Negated the X-axis component of the input vector to match the camera orientation. This is analogous to the existing Y-axis negation that maps "up" input to forward movement.

### Changes Made
**File:** `scripts/player.gd`

**Lines 96 and 101:** Changed `input_dir.x` to `-input_dir.x`

```gdscript
# Before (INCORRECT):
var input_3d = Vector3(input_dir.x, 0, -input_dir.y).normalized()
direction = Vector3(input_dir.x, 0, -input_dir.y).normalized()

# After (CORRECT):
var input_3d = Vector3(-input_dir.x, 0, -input_dir.y).normalized()
direction = Vector3(-input_dir.x, 0, -input_dir.y).normalized()
```

The change applies to both first-person and third-person modes.

## Technical Explanation

### Input System
- `Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")` returns:
  - X = +1 when right key/joystick is pressed
  - X = -1 when left key/joystick is pressed
  - Y = -1 when up key/joystick is pressed
  - Y = +1 when down key/joystick is pressed

### Camera Setup
- Third-person camera position: `Vector3(0, camera_height, camera_distance)`
  - camera_height = 5.0
  - camera_distance = 10.0
  - Result: camera at (0, 5, 10)
- Camera uses `look_at(global_position, Vector3.UP)` → faces -Z direction
- Player at origin (0, 0, 0), facing +Z direction
- Result: camera looks at player's face (face-to-face orientation)

### Input Transformation
With the negation:
1. **Joystick right** → input_dir.x = +1 → direction.x = -1 → player moves in -X direction → appears on RIGHT side of screen ✓
2. **Joystick left** → input_dir.x = -1 → direction.x = +1 → player moves in +X direction → appears on LEFT side of screen ✓
3. **Joystick up** → input_dir.y = -1 → direction.z = +1 → player moves in +Z direction (forward) ✓
4. **Joystick down** → input_dir.y = +1 → direction.z = -1 → player moves in -Z direction (backward) ✓

## How to Verify

### Keyboard Controls
1. Launch the game
2. Press **D** or **Right Arrow**
   - **Expected:** Avatar moves to the right side of the screen
3. Press **A** or **Left Arrow**
   - **Expected:** Avatar moves to the left side of the screen
4. Press **W** or **Up Arrow**
   - **Expected:** Avatar moves forward (up on screen in third-person)
5. Press **S** or **Down Arrow**
   - **Expected:** Avatar moves backward (down on screen in third-person)

### Mobile Joystick Controls
1. Launch the game on a mobile device or with touch input
2. Push the virtual joystick to the right
   - **Expected:** Avatar moves to the right side of the screen
3. Push the virtual joystick to the left
   - **Expected:** Avatar moves to the left side of the screen
4. Push the virtual joystick up
   - **Expected:** Avatar moves forward
5. Push the virtual joystick down
   - **Expected:** Avatar moves backward

### First-Person Mode
1. Toggle to first-person view (V key or menu button)
2. Repeat the same tests as above
3. The controls should feel natural:
   - Right input → view/movement turns right
   - Left input → view/movement turns left
   - Forward input → moves forward
   - Backward input → moves backward

Note: In first-person mode, the camera is rotated 180° (see line 200 in player.gd), but the input negation works correctly with this rotation to produce natural controls.

## Impact
This is a minimal, surgical fix that only affects the input transformation:
- **Lines changed:** 2 (just added minus sign before `input_dir.x` in two places)
- **Characters changed:** 2 (two minus signs)
- **Files modified:** 1 (`scripts/player.gd`)
- **Affected systems:** Player movement input handling
- **No changes to:** Camera system, physics, slope detection, rotation, or any other game systems

The fix is backward-compatible and doesn't introduce new dependencies.

## Related Issues
This is similar to the Y-axis negation fix documented in `BUGFIX_VERSION_NAVIGATION_MENU.md` and `FIRST_PERSON_MOVEMENT_FIX.md`, but applies to the X-axis (left/right) instead of the Y-axis (forward/backward).

The previous fixes correctly handled forward/backward inversion, but left/right inversion remained unaddressed until now.
