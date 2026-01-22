# Jetpack Gliding Feature

## Overview
This feature adds a smooth gliding mechanic when the jetpack button is released. Instead of instantly falling to the ground, the player will slowly descend (glide) until reaching the terrain.

## Implementation Details

### Changes to `scripts/player.gd`

#### New Export Variables
- `@export var glide_speed: float = 0.5` - Controls the slow descent speed when gliding after jetpack release

#### New State Variables
- `var is_gliding: bool = false` - Tracks if player is currently gliding
- `var was_jetpack_active: bool = false` - Tracks if jetpack was active in the previous frame

#### State Transitions
1. **Jetpack Active**: When the jetpack button is pressed:
   - `is_gliding = false` (disable gliding)
   - `was_jetpack_active = true` (mark jetpack as active)
   - `velocity.y = jetpack_speed` (ascend)

2. **Jetpack Released**: When the jetpack button is released:
   - `is_gliding = true` (start gliding)
   - `was_jetpack_active = false` (mark jetpack as inactive)
   - `velocity.y = -glide_speed` (slow descent)

3. **Landing**: When gliding and reaching terrain:
   - `is_gliding = false` (stop gliding)
   - `global_position.y = terrain_level` (snap to terrain)
   - `velocity.y = 0.0` (stop vertical movement)

### Configuration
The gliding speed can be adjusted in the Godot editor:
- Select the Player node
- In the Inspector, find the "Glide Speed" property
- Default value: 0.5 (slow descent)
- Lower values = slower gliding
- Higher values = faster descent

## Testing
Unit tests have been created in `tests/test_jetpack_glide.gd` that verify:
1. State transitions work correctly
2. Glide velocity is properly applied
3. Gliding stops when reaching terrain

Run tests with: `./run_tests.sh` or load the test scene: `tests/test_scene_jetpack_glide.tscn`

## User Experience
- Press and hold the jetpack button (spacebar or rocket icon) to ascend
- Release the button to start gliding slowly downward
- The player will gently descend until touching the ground
- Press the jetpack button again to stop gliding and resume ascending
