# Jetpack Landing Physics Fix - Implementation Summary

## Problem Statement (German)
"wenn zurück vom jetpack gelandet scheint man manchmal im Boden zu versinken bzw. durch Wände durch laufen zu können"

**Translation:** When landing from the jetpack, the player sometimes sinks into the ground or can walk through walls.

## Root Cause Analysis

The issue was caused by several physics problems in the landing mechanics:

1. **Direct Position Setting**: After `move_and_slide()`, the player's position was directly set to terrain level without any collision checking
2. **No Safe Margin**: The CharacterBody3D had no `safe_margin` configured, allowing high-speed movement to tunnel through thin geometry
3. **High Descent Velocity**: During glide-to-land transition, the vertical velocity wasn't dampened, causing the player to penetrate surfaces
4. **No Collision Recovery**: There was no mechanism to validate or recover from collision states after terrain snapping

## Solution - Collision-Aware Landing

### 1. Safe Margin Configuration
```gdscript
# Configure physics properties to prevent tunneling through walls
# Safe margin creates a small buffer zone around the collision shape
# This prevents high-speed movement from pushing through thin geometry
safe_margin = 0.08
```

The `safe_margin` of 0.08 units creates a buffer zone around the player's collision shape. This is a standard technique in Godot to prevent tunneling through thin geometry at high speeds.

### 2. Velocity Dampening on Landing
```gdscript
# Dampen velocity for smooth landing
velocity.y = max(velocity.y * 0.1, -0.5)
```

When the player lands, vertical velocity is reduced to 10% of its original value or clamped to -0.5 (whichever is greater). This prevents the high momentum from pushing the player through the terrain.

### 3. Collision-Aware Terrain Snapping
The new `_safe_snap_to_terrain()` function replaces direct position setting with a collision-aware approach:

```gdscript
func _safe_snap_to_terrain(terrain_level: float) -> void:
    var target_position = global_position
    target_position.y = terrain_level
    
    # Calculate the movement needed to reach terrain level
    var motion = target_position - global_position
    
    # Test if we can move to the target position without colliding
    var collision = test_move(global_transform, motion)
    
    if not collision:
        # Safe to move - no collision detected
        global_position.y = terrain_level
    else:
        # Collision detected - find the closest safe position
        # Use a binary search approach to find the maximum safe distance
        var safe_fraction = 0.5
        var step = 0.25
        
        for i in range(4):  # 4 iterations gives us 1/16 precision
            var test_motion = motion * safe_fraction
            if test_move(global_transform, test_motion):
                # Collision - try closer position
                safe_fraction -= step
            else:
                # No collision - can go further
                safe_fraction += step
            step *= 0.5
        
        # Apply the safe movement with additional safety margin
        # Clamp to ensure we never apply negative movement
        var final_fraction = clamp(safe_fraction - LANDING_SAFETY_MARGIN, 0.0, 1.0)
        global_position += motion * final_fraction
```

**Constants used:**
- `LANDING_BINARY_SEARCH_ITERATIONS = 4`: Binary search halves the search space each iteration (4 iterations = 1/16 precision)
- `LANDING_SAFETY_MARGIN = 0.05`: Additional 5% buffer to prevent floating-point precision issues at collision boundaries

**How it works:**

1. **Test Initial Movement**: Uses `test_move()` to check if moving to terrain level would cause a collision
2. **Binary Search**: If a collision is detected, performs a binary search to find the closest safe position
3. **Precision**: 4 iterations provide 1/16 precision, balancing performance and accuracy
4. **Safety Buffer**: Subtracts an additional 5% safety margin to ensure the player stays outside collision geometry

## Benefits

1. **No More Terrain Clipping**: The player can no longer sink into the ground when landing
2. **Wall Collision Prevention**: The safe margin and collision testing prevent walking through walls
3. **Smooth Landing**: Velocity dampening creates a more natural landing experience
4. **Robust Physics**: The binary search approach handles edge cases and complex collision scenarios
5. **Performance Optimized**: Only 4 iterations for the binary search keeps performance impact minimal

## Testing

New test file created: `tests/test_jetpack_collision_safe_landing.gd`

Tests verify:
- Safe margin configuration is properly set
- Velocity dampening works correctly during landing
- State transitions are handled properly
- Landing prevents collision issues

## Technical Details

### CharacterBody3D Properties Modified
- `safe_margin`: Set to 0.08 (prevents tunneling)

### New Functions Added
- `_safe_snap_to_terrain(terrain_level: float)`: Collision-aware terrain snapping

### Modified Landing Logic
- Added velocity dampening before terrain snap
- Replaced direct position setting with `_safe_snap_to_terrain()` call
- Improved landing state transitions

## Best Practices Applied

1. **Godot Physics API**: Uses `test_move()` which is the recommended way to test for collisions before moving
2. **Safe Margin**: Standard Godot technique for preventing tunneling at high speeds
3. **Binary Search**: Efficient algorithm for finding safe positions when collisions occur
4. **Minimal Changes**: Only modified the necessary parts of the landing logic
5. **Backward Compatibility**: All existing features (gliding, jetpack, terrain snapping) continue to work as before

## Performance Impact

Minimal - The collision testing and binary search only run during landing transitions, which is a small fraction of gameplay time. The 4-iteration binary search is negligible in terms of CPU usage.

## Known Limitations

- Very extreme collision scenarios (e.g., landing in a very tight space) might still position the player slightly above the exact terrain level
- The safety margin means the player will be positioned slightly above collision surfaces, which is the intended behavior for robust physics
