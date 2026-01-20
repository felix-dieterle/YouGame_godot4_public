# Ocean and Lighthouse System

## Overview

The ocean and lighthouse system adds large bodies of water (oceans/seas) that span multiple chunks, with lighthouses placed at regular intervals along coastlines to provide visual landmarks and navigation aids.

## Features

### Ocean Biome
- **Detection**: Chunks with average elevation ≤ -8.0 are classified as ocean
- **Visual**: Deep blue, semi-transparent water covering the entire chunk
- **Terrain**: Sandy/rocky seabed visible below the water surface
- **Coverage**: Oceans can span multiple adjacent chunks, creating large bodies of water

### Lighthouses
- **Placement**: Automatically placed on coastal chunks (non-ocean chunks adjacent to ocean)
- **Spacing**: Regular intervals of ~80 world units (configurable via `LIGHTHOUSE_SPACING`)
- **Structure**: 
  - 8-unit tall tower with red and white stripes
  - Beacon platform and light housing
  - Red conical roof
- **Beacon**: Warm yellow OmniLight3D with 30-unit range for visibility
- **Position**: Elevated coastal positions for maximum visibility

## Implementation Details

### Constants (in `chunk.gd`)

```gdscript
const OCEAN_LEVEL = -8.0                    # Elevation threshold for ocean biome
const LIGHTHOUSE_SEED_OFFSET = 77777        # Seed offset for lighthouse placement
const LIGHTHOUSE_SPACING = 80.0             # Distance between lighthouses
```

### Procedural Lighthouse Model (in `procedural_models.gd`)

```gdscript
const LIGHTHOUSE_TOWER_HEIGHT = 8.0         # Tower height
const LIGHTHOUSE_TOWER_RADIUS = 0.8         # Tower radius
const LIGHTHOUSE_TOWER_SEGMENTS = 8         # Cylinder segments
const LIGHTHOUSE_BEACON_HEIGHT = 1.5        # Beacon housing height
const LIGHTHOUSE_BEACON_RADIUS = 1.2        # Beacon platform radius
```

### Generation Pipeline

The chunk generation pipeline has been extended:

1. **Heightmap Generation** - Terrain noise generation
2. **Walkability Calculation** - Slope-based walkability
3. **Metadata Calculation** - **Ocean biome detection added here**
4. **Lake Generation** - Valley lakes (existing feature)
5. **Ocean Generation** - **New: Create ocean water mesh if biome is ocean**
6. **Mesh Creation** - Terrain mesh with ocean floor coloring
7. **Object Placement** - Rocks, trees, buildings
8. **Path Generation** - Connecting paths
9. **Lighthouse Placement** - **New: Place lighthouses on coastal chunks**

### Ocean Detection

```gdscript
func _calculate_metadata() -> void:
    var avg_height = # calculate average chunk height
    
    if avg_height <= OCEAN_LEVEL:
        biome = "ocean"
        landmark_type = "ocean"
        is_ocean = true
```

### Coastal Detection

Lighthouses are placed on chunks that:
1. Are NOT ocean themselves
2. Have at least one ocean neighbor (north, south, east, or west)
3. Are positioned on the lighthouse grid (every `LIGHTHOUSE_SPACING` units)

```gdscript
func _place_lighthouses_if_coastal() -> void:
    if is_ocean:
        return  # Don't place on ocean chunks
    
    # Check grid position
    var spacing_chunks = max(1, int(LIGHTHOUSE_SPACING / CHUNK_SIZE))
    var on_x_grid = (chunk_x % spacing_chunks) == 0
    var on_z_grid = (chunk_z % spacing_chunks) == 0
    
    if not (on_x_grid or on_z_grid):
        return
    
    # Check for ocean neighbors
    # ... coastal detection logic ...
```

### Lighthouse Construction

Each lighthouse consists of:

1. **Tower**: 4 cylindrical sections with alternating white/red colors
2. **Platform**: Dark gray cylinder at the top of the tower
3. **Beacon Housing**: Yellow-tinted translucent cylinder for the light
4. **Roof**: Red conical cap
5. **Light**: OmniLight3D with warm yellow color and 30-unit range

## Performance Considerations

- **Ocean Water**: Simple quad mesh per chunk (2 triangles), minimal overhead
- **Lighthouses**: Placed sparingly on grid pattern, not every coastal chunk
- **Coastal Detection**: Efficient neighbor height estimation without full generation
- **Light Count**: Limited by spacing constraints to avoid too many dynamic lights

## Visual Characteristics

### Ocean Water
- **Color**: Deep blue (0.1, 0.3, 0.6) with 70% opacity
- **Material**: Specular reflections, very smooth (roughness 0.05)
- **Double-sided**: Visible from above and below water surface

### Lighthouse
- **Tower Colors**: White (0.95, 0.95, 0.95) and Red (0.8, 0.2, 0.2)
- **Beacon Light**: Warm yellow (1.0, 0.9, 0.6)
- **Material**: Moderate roughness (0.6) for painted surface appearance

## Testing

Two test suites verify the ocean and lighthouse system:

### Unit Test (`test_ocean_lighthouse.gd`)
- Verifies lighthouse mesh/material creation
- Tests ocean chunk detection
- Validates coastal chunk lighthouse placement

### Visual Test (`test_ocean_visual.gd`)
- Creates a 5×5 grid of chunks
- Captures screenshots of ocean and lighthouses
- Reports statistics on ocean coverage and lighthouse placement

Run tests:
```bash
./run_tests.sh
# or
godot --headless res://tests/test_scene_ocean_lighthouse.tscn
godot --headless res://tests/test_scene_ocean_visual.tscn
```

## Usage Example

Ocean and lighthouses are automatically generated during world creation:

```gdscript
# Ocean chunks are automatically detected based on elevation
var chunk = Chunk.new(-5, -5, 12345)  # Low coordinates likely ocean
chunk.generate()

if chunk.is_ocean:
    print("Ocean chunk created with water mesh")
    
if chunk.placed_lighthouses.size() > 0:
    print("Coastal chunk with %d lighthouses" % chunk.placed_lighthouses.size())
```

## Configuration

Adjust ocean and lighthouse generation by modifying constants:

- **Ocean Level**: Change `OCEAN_LEVEL` to adjust what elevation counts as ocean
- **Lighthouse Spacing**: Modify `LIGHTHOUSE_SPACING` for more/fewer lighthouses
- **Lighthouse Appearance**: Edit constants in `procedural_models.gd` for size/proportions

## Future Enhancements

Potential improvements:
- Animated water surface (wave shader)
- Rotating lighthouse beacon
- Shore/beach transition zones
- Ocean-specific features (shipwrecks, islands)
- Lighthouse activation at night only
- Foghorn sound effects

## Related Systems

- **Biome System**: Ocean is a new biome type alongside grassland, mountain, rocky_hills
- **Lake System**: Similar water rendering but localized to valley chunks
- **Cluster System**: Lighthouses use similar placement logic to settlements/forests
- **Procedural Models**: Lighthouse model uses same system as trees/buildings/rocks
