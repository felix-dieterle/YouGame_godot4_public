# First-Person Movement Fix

## Problem
When in first-person mode, there were two issues with movement controls:

**First issue (previously fixed):**
- Movement was still world-relative instead of player-relative
- Pushing forward on the joystick always moved the player north (world coordinates)
- The player's facing direction had no effect on movement direction
- This felt unnatural in first-person view

**Second issue (current fix):**
- Even after making movement player-relative, the controls were inverted
- Pushing forward on the joystick made the player move backward
- Pushing backward on the joystick made the player move forward
- This happened because the input Y-axis wasn't properly mapped to the 3D coordinate system

## Solution
Modified the movement direction calculation in `scripts/player.gd` in two stages:

1. **First fix**: Made movement player-relative in first-person mode by rotating the input vector
2. **Second fix**: Corrected inverted controls by negating the Y-axis component

**After both fixes:**
- In **first-person mode**: Movement is relative to where the player is facing with correct forward/backward
  - Forward → moves in the direction you're looking (fixed: was backward)
  - Right → strafes right relative to your view direction
  - Backward → moves backward relative to your view (fixed: was forward)
  - Left → strafes left relative to your view direction
  
- In **third-person mode**: Movement remains world-relative (unchanged behavior)
  - Forward → moves north
  - Right → moves east
  - Backward → moves south
  - Left → moves west

## Technical Details

**Changed in `scripts/player.gd` (_physics_process):**

```gdscript
# OLD CODE (original line 80):
var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()

# FIRST FIX - Made movement player-relative in first-person:
var direction = Vector3.ZERO
if input_dir.length() > 0.01:
    if is_first_person:
        # First-person: Transform input by player's rotation
        # Forward (input_dir.y) should move in the direction player is facing
        var input_3d = Vector3(input_dir.x, 0, input_dir.y).normalized()
        direction = input_3d.rotated(Vector3.UP, rotation.y)
    else:
        # Third-person: World-relative movement (original behavior)
        direction = Vector3(input_dir.x, 0, input_dir.y).normalized()

# SECOND FIX - Corrected inverted forward/backward controls (line 89):
# Changed: var input_3d = Vector3(input_dir.x, 0, input_dir.y).normalized()
# To:      var input_3d = Vector3(input_dir.x, 0, -input_dir.y).normalized()
# 
# This negation is necessary because:
# - Input.get_vector() returns negative Y for "up" input
# - The player rotates to face the movement direction using atan2(x, z)
# - Without negation, pressing "up" creates Vector3(0, 0, -1)
# - atan2(0, -1) = 180°, making player face backward while moving
# - With negation, pressing "up" creates Vector3(0, 0, 1)
# - atan2(0, 1) = 0°, making player correctly face forward
```

The key changes are:
1. Using `rotated(Vector3.UP, rotation.y)` to transform input by player rotation (first fix)
2. Negating `input_dir.y` to fix inverted forward/backward controls (second fix)

## How to Test

1. Start the game
2. Press **V** key or tap **"👁 Toggle First Person View"** button to switch to first-person
3. Move the character using WASD or joystick:
   - **W** or **forward**: Should move in the direction you're facing
   - **A** or **left**: Should strafe left
   - **S** or **backward**: Should move backward
   - **D** or **right**: Should strafe right
4. Turn the character by moving in a different direction (the player rotates to face movement)
5. Verify that forward always moves in the direction you're facing, not always north
6. Switch back to third-person with **V** and verify world-relative movement still works

## Related Files
- `scripts/player.gd` - Main player controller with movement logic

## Impact
This is a minimal, surgical fix that only changes the movement direction calculation. The rotation behavior remains the same in both modes (player rotates to face movement direction). All other systems are unaffected.
