# Jetpack Speed Boost Feature

## Overview
This feature adds a 4x horizontal movement speed multiplier when the jetpack is active. When the player activates the jetpack, they move 4 times faster horizontally while ascending or gliding.

## Implementation Details

### Changes to `scripts/player.gd`

#### New Export Variable
- `@export var jetpack_move_speed_multiplier: float = 4.0` - Controls the horizontal speed multiplier when jetpack is active

#### Movement Speed Calculation
The movement speed is now calculated based on jetpack state:
```gdscript
var current_move_speed = move_speed
if jetpack_active:
    current_move_speed = move_speed * jetpack_move_speed_multiplier

velocity.x = direction.x * current_move_speed
velocity.z = direction.z * current_move_speed
```

#### Speed Calculations
- **Normal movement speed**: 5.0 units/second
- **Jetpack horizontal speed**: 5.0 * 4.0 = 20.0 units/second
- **Jetpack vertical speed**: 3.0 units/second (unchanged)

### Configuration
The speed multiplier can be adjusted in the Godot editor:
- Select the Player node
- In the Inspector, find the "Jetpack Move Speed Multiplier" property
- Default value: 4.0 (4x normal speed)
- Adjust to any value to fine-tune the boost

## Testing
Unit tests have been created in `tests/test_jetpack_speed_boost.gd` that verify:
1. The multiplier is set to 4.0 by default
2. Horizontal speed is 4x when jetpack is active
3. Normal speed is maintained when jetpack is not active

Run tests with: `./run_tests.sh` or load the test scene: `tests/test_scene_jetpack_speed_boost.tscn`

## User Experience
- Move normally at 5.0 units/second when walking
- Activate the jetpack (spacebar or rocket icon) to:
  - Ascend at 3.0 units/second vertically
  - Move at 20.0 units/second horizontally (4x normal speed)
- Release the jetpack to glide back down at normal horizontal speed
- The speed boost makes jetpack mode feel more powerful and useful for traversal
