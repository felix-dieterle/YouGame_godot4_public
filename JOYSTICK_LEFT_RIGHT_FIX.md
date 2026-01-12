# Joystick Left/Right Navigation Fix

## Date
2026-01-12

## Issue Fixed
Right/Left joystick navigation was inverted. When pushing the joystick right, the avatar moved left, and vice versa.

## Root Cause
The previous fix (documented in `NAVIGATION_FIX.md`) incorrectly analyzed the camera setup as "face-to-face" when it's actually a standard "behind the player" third-person camera.

### Actual Camera Setup
From `scripts/player.gd` lines 52-53:
```gdscript
camera.position = Vector3(0, camera_height, camera_distance)  # (0, 5, 10)
camera.look_at(global_position, Vector3.UP)  # Looking at (0, 0, 0)
```

This means:
- **Camera is at (0, 5, 10)** - positioned at +Z, behind the player
- **Camera looks at (0, 0, 0)** - looking towards the player
- **Camera sees the BACK of the player** (standard third-person view)

### Correct Input Mapping
With a "behind the player" camera:
- When player moves **+X (right in world)**, they appear on **RIGHT side** of screen ✓
- When player moves **-X (left in world)**, they appear on **LEFT side** of screen ✓
- When player moves **+Z (forward)**, they move **AWAY from camera** (up on screen) ✓
- When player moves **-Z (backward)**, they move **TOWARD camera** (down on screen) ✓

### Input System
`Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")` returns:
- **X = +1** when right key/joystick is pressed
- **X = -1** when left key/joystick is pressed
- **Y = -1** when up key/joystick is pressed (UI coordinates)
- **Y = +1** when down key/joystick is pressed (UI coordinates)

### Required Transformation
- **X-axis**: NO negation needed (input_dir.x → direction.x)
- **Y-axis**: YES negation needed (input_dir.y → -direction.z) to convert UI coordinates to 3D world coordinates

## Solution
Removed the incorrect X-axis negation that was causing the inversion.

### Changes Made
**File:** `scripts/player.gd`

**Lines 97 and 102:** Changed `-input_dir.x` back to `input_dir.x`

```gdscript
# Before (INCORRECT - caused inversion):
var input_3d = Vector3(-input_dir.x, 0, -input_dir.y).normalized()
direction = Vector3(-input_dir.x, 0, -input_dir.y).normalized()

# After (CORRECT):
var input_3d = Vector3(input_dir.x, 0, -input_dir.y).normalized()
direction = Vector3(input_dir.x, 0, -input_dir.y).normalized()
```

The change applies to both first-person and third-person modes.

## Technical Explanation

### Expected Behavior (with correct mapping)
1. **Joystick right** → input_dir.x = +1 → direction.x = +1 → player moves in +X direction → appears on RIGHT side of screen ✓
2. **Joystick left** → input_dir.x = -1 → direction.x = -1 → player moves in -X direction → appears on LEFT side of screen ✓
3. **Joystick up** → input_dir.y = -1 → direction.z = +1 → player moves in +Z direction (forward) ✓
4. **Joystick down** → input_dir.y = +1 → direction.z = -1 → player moves in -Z direction (backward) ✓

### Why Y-axis Needs Negation (but X-axis Doesn't)
- **UI coordinates**: Y axis points DOWN (positive Y = down on screen)
- **3D world coordinates**: Z axis points FORWARD in this game (positive Z = forward movement)
- **Mapping**: "up" input (negative Y in UI) should produce forward movement (positive Z in 3D)
- **Therefore**: We negate Y to convert from UI to 3D coordinates

For X-axis:
- **UI coordinates**: X axis points RIGHT (positive X = right on screen)
- **3D world coordinates**: X axis points RIGHT (positive X = right in world)
- **Mapping**: "right" input (positive X in UI) should produce right movement (positive X in 3D)
- **Therefore**: NO negation needed for X-axis

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

## Impact
This is a minimal, surgical fix that corrects the input transformation:
- **Lines changed:** 2 (removed minus sign before `input_dir.x` in two places)
- **Characters changed:** 2 (removed two minus signs)
- **Files modified:** 1 (`scripts/player.gd`)
- **Affected systems:** Player movement input handling
- **No changes to:** Camera system, physics, slope detection, rotation, or any other game systems

The fix is backward-compatible and doesn't introduce new dependencies.

## Related Issues
This fix **corrects** the erroneous change documented in `NAVIGATION_FIX.md`. That document incorrectly described the camera setup as "face-to-face" when it's actually "behind the player".

The Y-axis negation (for forward/backward) was and remains correct, as documented in `BUGFIX_VERSION_NAVIGATION_MENU.md` and `FIRST_PERSON_MOVEMENT_FIX.md`.

---

## Update: First-Person Mode Fix (2026-01-12)

### Additional Issue Discovered
After the initial fix above, it was discovered that **first-person mode still had inverted left/right controls**. When using joystick controls in first-person view:
- Pushing joystick RIGHT made the player turn/look LEFT
- Pushing joystick LEFT made the player turn/look RIGHT

### Root Cause
The first-person camera is rotated 180° (PI radians) on the Y-axis to look forward from the player's position (see `scripts/player.gd` line 204):
```gdscript
camera.rotation = Vector3(0, PI, 0)
```

This 180° rotation inverts the left/right axis from the player's perspective. The original fix correctly handled third-person view but didn't account for the camera rotation in first-person mode.

### Solution for First-Person Mode
Negate `input_dir.x` when in first-person mode to compensate for the 180° camera rotation.

**File:** `scripts/player.gd`  
**line 100:** Changed `input_dir.x` to `-input_dir.x` in first-person mode only

```gdscript
# Before (INCORRECT for first-person):
var input_3d = Vector3(input_dir.x, 0, -input_dir.y).normalized()

# After (CORRECT for first-person):
var input_3d = Vector3(-input_dir.x, 0, -input_dir.y).normalized()
```

### Technical Explanation
1. **Third-person mode** (unchanged):
   - Camera looks at player from behind
   - No X-axis negation needed
   - `input_dir.x` → `direction.x` (direct mapping)

2. **First-person mode** (now fixed):
   - Camera is rotated 180° to look forward
   - X-axis negation needed to compensate for camera rotation
   - `-input_dir.x` → `direction.x` (inverted mapping)

### Verification
In first-person mode:
1. Pushing joystick/keys **right** → player turns **right** ✓
2. Pushing joystick/keys **left** → player turns **left** ✓
3. Pushing joystick/keys **forward** → player moves **forward** ✓
4. Pushing joystick/keys **backward** → player moves **backward** ✓

### Impact
- **Lines changed:** 1 (added minus sign before `input_dir.x` in first-person mode)
- **Characters changed:** 1 (added one minus sign)
- **Files modified:** 1 (`scripts/player.gd`)
- **Affected systems:** First-person mode input handling only
- **Third-person mode:** Unchanged and working correctly
