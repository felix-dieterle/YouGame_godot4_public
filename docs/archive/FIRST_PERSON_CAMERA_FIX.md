# First-Person Camera Fix

## Problem
The first-person camera switch appeared disabled - nothing visually changed when clicking the toggle button or pressing the V key.

## Root Cause
In the `_update_camera()` function in `scripts/player.gd`, when switching to first-person mode, the camera rotation was explicitly set to `Vector3(0, 0, 0)`:

```gdscript
camera.rotation = Vector3(0, 0, 0)
```

This caused the camera to always face north (forward in world coordinates) regardless of which direction the player was facing. As a result:
- The camera didn't rotate with the player's movement
- Switching to first-person mode showed no visual difference
- Users couldn't see in the direction their character was facing

## Solution
The camera is a child node of the player, so it naturally inherits the player's rotation transformations. By removing the explicit rotation reset, the camera now properly follows the player's Y-axis rotation.

**Changed in `scripts/player.gd`:**
```gdscript
func _update_camera():
    if camera:
        if is_first_person:
            camera.position = Vector3(0, first_person_height, 0)
            # In first-person, camera inherits player's rotation automatically
            # No need to set rotation - let it follow the player's Y rotation
        else:
            camera.position = Vector3(0, camera_height, camera_distance)
            camera.look_at(global_position, Vector3.UP)
```

## How to Test
1. Start the game
2. Move the player character using WASD or arrow keys
3. Press **V** key or tap the **"👁 Toggle First Person View"** button in the settings menu
4. **Expected behavior in first-person mode:**
   - Camera view should be at eye level (~1.6 units high)
   - Camera should face the same direction as the player
   - When moving, the camera should rotate to face the movement direction
   - Robot body parts should be hidden
   - Head bobbing animation should be visible when moving
5. Press **V** again to return to third-person mode
6. **Expected behavior in third-person mode:**
   - Camera should be positioned behind and above the player
   - Robot body should be visible
   - Camera should follow the player from a distance

## Technical Details
- The player's rotation is updated in `_physics_process()` at line 105: `rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)`
- Since the camera is a child node, it inherits this rotation transformation automatically
- In first-person mode, we only need to set the camera's local position, not its rotation
- In third-person mode, we use `look_at()` to orient the camera toward the player

## Impact
This is a minimal, surgical fix that only changes the camera rotation behavior in first-person mode. No other systems are affected.
