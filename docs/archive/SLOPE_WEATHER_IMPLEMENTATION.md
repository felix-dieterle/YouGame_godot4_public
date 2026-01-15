# Slope Restriction and Weather System Implementation

## Problem Statement (German)
> Wie haben wir bisher versucht zu betreiben das der Avatar schrägen großer 30% hoch kommt und warum funktioniert diese Einschränkung in der Praxis nicht? der Avatar rutscht einfach jeder schräge hoch egal wie steil. wie macht man das in der Praxis?

**Translation**: How have we tried to ensure the avatar can climb slopes greater than 30% and why doesn't this restriction work in practice? The avatar simply slides up every slope no matter how steep. How do you do this in practice?

## Solution: Slope Restriction

### Previous Implementation (Not Working)
The previous approach only set `floor_max_angle` on the CharacterBody3D:
```gdscript
floor_max_angle = deg_to_rad(max_slope_angle)
```

**Why it didn't work**: In Godot, `floor_max_angle` only determines what surfaces are considered "floors" for collision detection and physics calculations. It does **not** prevent the character from moving up steep slopes - it only affects whether the character can stand on those surfaces.

### New Implementation (Working)
The new implementation actively checks the slope at the intended position **before** allowing movement:

1. **Added `get_slope_at_world_pos()` to Chunk** (`scripts/chunk.gd`):
   - Calculates the slope angle at any world position within the chunk
   - Uses the same slope calculation as the walkability map (max height difference between cell corners)

2. **Added `get_slope_at_position()` to WorldManager** (`scripts/world_manager.gd`):
   - Provides easy access to slope information from any world position
   - Delegates to the appropriate chunk

3. **Modified Player movement** (`scripts/player.gd`):
   - Before setting velocity, calculates the intended position
   - Checks the slope at that position using `world_manager.get_slope_at_position()`
   - Only allows movement if `slope_at_position <= max_slope_angle`
   - If the slope is too steep, gradually stops the player's momentum

### Code Changes
```gdscript
# In player.gd _physics_process()
if direction:
    # Check slope at intended position
    var intended_position = global_position + direction * move_speed * delta
    var can_move = true
    
    if world_manager:
        var slope_at_position = world_manager.get_slope_at_position(intended_position)
        # Only allow movement if slope is walkable
        if slope_at_position > max_slope_angle:
            can_move = false
    
    if can_move:
        # Normal movement
        velocity.x = direction.x * move_speed
        velocity.z = direction.z * move_speed
        # ...
    else:
        # Stop movement if trying to climb too steep slope
        velocity.x = move_toward(velocity.x, 0, move_speed * delta * 2.0)
        velocity.z = move_toward(velocity.z, 0, move_speed * delta * 2.0)
```

## Weather System

### Problem Statement (German)
> Können wir ein rudimentären Wetter implementieren dass sich zufällig über die Zeit unauffällig verändert?

**Translation**: Can we implement a rudimentary weather system that changes randomly over time in an unobtrusive way?

### Implementation
Created a new `WeatherSystem` script (`scripts/weather_system.gd`) with the following features:

#### Weather States
- **CLEAR**: No weather effects
- **LIGHT_FOG**: Subtle fog (density: 0.001)
- **HEAVY_FOG**: Denser fog (density: 0.005)
- **LIGHT_RAIN**: Light rain particles with minimal fog
- **HEAVY_RAIN**: Heavy rain particles with moderate fog

#### Features
1. **Gradual Transitions**: Weather changes smoothly over 30 seconds (configurable)
2. **Random Duration**: Each weather state lasts 2-5 minutes (configurable)
3. **Weighted Random Selection**: More likely to be clear (40%) than heavy rain (5%)
4. **Visual Effects**:
   - Fog system using Godot's built-in fog environment
   - GPU particle-based rain that follows the player
   - Rain particles are semi-transparent quads falling downward

#### Configuration
```gdscript
@export var min_weather_duration: float = 120.0  # 2 minutes minimum
@export var max_weather_duration: float = 300.0  # 5 minutes maximum
@export var transition_duration: float = 30.0    # 30 seconds to transition
```

#### Integration
The weather system was added to `scenes/main.tscn` as a new node:
```
[node name="WeatherSystem" type="Node3D" parent="."]
script = ExtResource("9_weather")
```

It automatically finds the existing `WorldEnvironment` and modifies its fog settings dynamically.

## Testing

A test file was created at `tests/test_slope_weather.gd` to verify:
- Slope calculation returns valid values (0-90 degrees)
- WorldManager correctly retrieves slope information
- Slope queries outside loaded chunks return 0.0

## Files Modified
- `scripts/chunk.gd`: Added `get_slope_at_world_pos()` method
- `scripts/world_manager.gd`: Added `get_slope_at_position()` method
- `scripts/player.gd`: Modified `_physics_process()` to check slope before movement
- `scenes/main.tscn`: Added WeatherSystem node and Player group

## Files Created
- `scripts/weather_system.gd`: New weather system implementation
- `tests/test_slope_weather.gd`: Tests for slope functionality

## How to Use

### Slope Restriction
The slope restriction is automatic. The player will not be able to move up slopes steeper than 30 degrees (configurable via `max_slope_angle` on the Player node).

### Weather System
The weather system runs automatically. To adjust settings:
1. Select the `WeatherSystem` node in the scene tree
2. Modify the exported variables in the Inspector:
   - `min_weather_duration`: Minimum time in each weather state
   - `max_weather_duration`: Maximum time in each weather state
   - `transition_duration`: How long transitions take

## Technical Notes

### Why This Approach Works
1. **Proactive Checking**: Instead of relying on physics constraints, we actively prevent movement before it happens
2. **Accurate Slope Data**: We use the same slope calculation that generates the walkability map
3. **Smooth Experience**: The player gradually slows down when approaching steep slopes rather than hitting an invisible wall

### Weather System Design
1. **Unobtrusive**: Changes are gradual (30 second transitions) and random intervals
2. **Follows Player**: Rain particles are positioned above the player and move with them
3. **Weighted Random**: More common weather (clear, light fog) is more likely than rare weather (heavy rain)
4. **Performance**: Uses GPU particles for efficient rain rendering
