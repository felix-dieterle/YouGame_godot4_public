# First-Person View, Walking Animations, and Lakes Feature Documentation

This document describes the new features added to YouGame for enhanced player experience and terrain variety.

## Features Overview

### 1. First-Person / Third-Person Camera Toggle

Players can now switch between third-person and first-person views on the fly.

#### How to Use
- Press the **V** key to toggle between camera views
- **First-Person View** (default): Camera positioned at eye level, robot body hidden
- **Third-Person View**: Camera positioned behind and above the player

#### Technical Details
- First-person camera height: 1.6 units (configurable via `@export var first_person_height`)
- Robot body parts automatically hide in first-person mode
- Camera smoothly transitions between views
- Mouse wheel zoom only works in third-person mode

#### Implementation
```gdscript
# In player.gd
var is_first_person: bool = false

func _toggle_camera_view():
    is_first_person = not is_first_person
    _update_camera()
    
    # Toggle visibility of robot body parts
    for part in robot_parts:
        part.visible = not is_first_person
```

### 2. Walking Animations (Head Bobbing)

First-person view includes immersive head bobbing animation that simulates natural walking motion.

#### Features
- **Dynamic head bob**: Camera moves up and down as you walk
- **Speed-responsive**: Bob frequency matches movement speed
- **Smooth reset**: Animation smoothly stops when player stops moving
- **Configurable parameters**:
  - `head_bob_frequency`: 2.0 (speed of bobbing)
  - `head_bob_amplitude`: 0.1 (intensity of bobbing)

#### How It Works
The head bobbing uses a sine wave function based on movement time:
```gdscript
if is_first_person and camera:
    var bob_offset = sin(head_bob_time) * head_bob_amplitude
    camera.position.y = first_person_height + bob_offset
```

### 3. Lakes in Valleys

Valleys now have a chance to contain lakes where players sink knee-deep.

#### Lake Generation
- **Location**: Only spawns in valley terrain (average height < -5.0)
- **Probability**: 30% chance per valley chunk
- **Size**: Radius varies between 8.0 and 14.0 units
- **Position**: Center of chunk
- **Depth**: Maximum 1.5 units (knee-deep) at the center

#### Visual Appearance
- Semi-transparent blue water surface
- Circular shape with 16 segments
- Reflective material (low roughness, specular highlights)
- Visible from both sides (no culling)

#### Water Interaction
Players automatically sink into water based on distance from lake center:
- **Center**: Full depth (1.5 units)
- **Edge**: Shallow depth (approaching 0)
- **Outside lake**: No effect

The sinking effect is calculated as:
```gdscript
var depth_factor = 1.0 - (dist_to_center / lake_radius)
var water_depth = depth_factor * lake_depth
```

#### Technical Implementation
```gdscript
# In chunk.gd
func _generate_lake_if_valley():
    if landmark_type != "valley":
        return
    
    var rng = RandomNumberGenerator.new()
    rng.seed = hash(Vector2i(chunk_x, chunk_z)) + seed_value
    
    if rng.randf() > 0.3:  # 30% chance
        return
    
    has_lake = true
    lake_center = Vector2(CHUNK_SIZE / 2.0, CHUNK_SIZE / 2.0)
    lake_radius = rng.randf_range(8.0, 14.0)
    
    _create_water_mesh()
```

## Configuration

### Player Settings (player.gd)

```gdscript
# Movement
@export var move_speed: float = 5.0
@export var rotation_speed: float = 3.0

# Third-person camera
@export var camera_distance: float = 10.0
@export var camera_height: float = 5.0

# First-person camera
@export var first_person_height: float = 1.6

# Walking animation
@export var head_bob_frequency: float = 2.0
@export var head_bob_amplitude: float = 0.1
```

### Lake Settings (chunk.gd)

```gdscript
# Lake generation probability
# Currently: 30% in valleys (line 224)
if rng.randf() > 0.3:

# Lake size range
lake_radius = rng.randf_range(8.0, 14.0)

# Water depth
var lake_depth: float = 1.5  # Knee-deep
```

## Controls

| Action | Key | Description |
|--------|-----|-------------|
| Move | W/A/S/D or Arrow Keys | Move player |
| Toggle Camera | V | Switch between first/third person |
| Zoom (3rd person only) | Mouse Wheel | Adjust camera distance |
| Mobile | Touch Joystick | Virtual joystick for mobile devices |

## Testing

The following tests verify the new features:

### Lake Generation Test
```bash
# Tests that lakes generate correctly in valleys
# Verifies lake properties (radius, position, etc.)
./run_tests.sh
```

Expected output:
```
--- Test: Lake Generation in Valleys ---
Found lake in valley chunk (X, Y) with radius R
Found N valleys out of M chunks tested
Found L lakes in valleys
PASS: Lake generation system is working
```

### Water Depth Test
```bash
# Tests water depth calculation at different positions
./run_tests.sh
```

Expected output:
```
--- Test: Water Depth Calculation ---
Water depth at center: 1.50
Water depth near edge: 0.15
Water depth outside lake: 0.00
PASS: Water depth calculation is correct
```

## Performance Considerations

### First-Person Mode
- **Benefit**: Hiding robot body parts in first-person reduces render complexity
- **Impact**: Negligible - only affects 6 mesh instances
- **Head bobbing**: Simple sine calculation, no performance impact

### Lakes
- **Water mesh**: 16 triangles per lake (32 total triangles)
- **Transparency**: Uses alpha blending (moderate GPU cost)
- **Generation**: Only in valleys (~30% of those), so limited overhead
- **Memory**: Minimal - one MeshInstance3D per lake

**Optimization tips**:
- Lakes use a fixed segment count (16) for consistent performance
- Water material uses simple color vertex attributes
- No real-time water simulation (static surface)

## Known Limitations

1. **First-person rotation**: Player still rotates based on movement direction (no mouse look)
2. **Water surface**: Static water level (no waves or animation)
3. **Lake placement**: Always at chunk center (not based on lowest point)
4. **Head bobbing**: Same intensity regardless of terrain slope

## Future Enhancements

Potential improvements:
- [ ] Mouse-look camera control in first-person
- [ ] Animated water surface with simple wave shader
- [ ] Dynamic lake placement at lowest elevation in valley
- [ ] Swimming mechanic for deeper water
- [ ] Terrain-aware head bobbing (more intense on slopes)
- [ ] Footstep sounds synchronized with head bob
- [ ] Splash effects when entering water

## Examples

### Customizing Head Bob
```gdscript
# Make head bobbing more pronounced
@export var head_bob_amplitude: float = 0.2  # Default: 0.1

# Make head bobbing faster (jogging effect)
@export var head_bob_frequency: float = 3.5  # Default: 2.0
```

### Adjusting Lake Frequency
```gdscript
# In chunk.gd, _generate_lake_if_valley():
# More lakes (50% chance)
if rng.randf() > 0.5:
    return

# Fewer lakes (10% chance)
if rng.randf() > 0.1:
    return
```

### Changing Water Depth
```gdscript
# In chunk.gd
var lake_depth: float = 1.0  # Ankle-deep
var lake_depth: float = 2.5  # Waist-deep
```

## Troubleshooting

### Camera doesn't switch views
- Verify input mapping exists in project.godot
- Check that "toggle_camera_view" action is bound to V key
- Ensure player script is attached to Player node

### No head bobbing in first-person
- Confirm you're actually in first-person mode (robot should be invisible)
- Check that you're moving (head bob only occurs during movement)
- Verify `head_bob_amplitude` is not set to 0

### Lakes don't appear
- Lakes only spawn in valleys (average terrain height < -5.0)
- Only 30% of valleys get lakes (random)
- Try exploring different chunks or changing the seed
- Check console for any error messages

### Player doesn't sink in water
- Verify WorldManager is properly assigned
- Check that chunk has a lake (only in valleys)
- Ensure `get_water_depth_at_position()` is being called

## Related Documentation

- [Model Integration Guide](MODEL_INTEGRATION.md) - How to add custom 3D models
- [Features Documentation](FEATURES.md) - Overview of all game features
- [Development Guide](DEVELOPMENT.md) - Development workflow and practices

## Credits

Implementation: GitHub Copilot
Requested features: First-person view, walking animations, valley lakes
