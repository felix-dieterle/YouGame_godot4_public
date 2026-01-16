# Path System and Starting Location - Documentation

## Overview / Übersicht

**English**: This document describes the path/road system (Wegesystem) and starting location (Startplatz) implementation for the procedurally generated world.

**Deutsch**: Dieses Dokument beschreibt die Implementierung des Wegesystems und Startplatzes für die prozedural generierte Welt.

## Features / Funktionen

### Path System (Wegesystem)

The path system generates procedural paths that:

- **Start from origin**: Main paths begin at the starting location (chunk 0,0)
- **Continue across chunks**: Paths seamlessly extend to neighboring chunks
- **Random branching**: Paths can branch with configurable probability (15% default)
- **Target destinations**: Branches attempt to lead toward forests and settlements
- **Endpoint detection**: Paths can randomly end or terminate near clusters
- **Visual representation**: Paths are rendered as colored mesh overlays on terrain

### Starting Location (Startplatz)

The starting location provides:

- **Simple procedural objects**: No external model files required
- **Central cairn**: A stacked stone marker at the center (position 0,0,0)
- **Standing stones**: 6 marker stones arranged in a circle
- **Terrain adaptation**: All objects adjust their height to match terrain
- **Consistent generation**: Fixed seed ensures same appearance

## Architecture / Architektur

### Class Structure

```
PathSystem (static class)
├── PathSegment (inner class)
│   ├── segment_id: int
│   ├── chunk_pos: Vector2i
│   ├── start_pos: Vector2
│   ├── end_pos: Vector2
│   ├── path_type: PathType
│   ├── width: float
│   ├── next_segments: Array[int]
│   └── is_endpoint: bool
└── Static methods for path generation

StartingLocation (Node3D)
├── marker_stones: Array[MeshInstance3D]
├── central_marker: MeshInstance3D
└── Methods for generation and terrain adaptation
```

### Path Types (Wegtypen)

```gdscript
enum PathType {
    MAIN_PATH,      # Main path from starting location
    BRANCH,         # Generic branch from main path
    FOREST_PATH,    # Path targeting forest cluster
    VILLAGE_PATH    # Path targeting settlement cluster
}
```

## Integration

### Chunk Integration

Paths are automatically generated during chunk creation:

```gdscript
# In chunk.gd generate() function
func generate():
    # ... existing terrain generation ...
    _generate_paths()  # New: Generate path segments
```

The `_generate_paths()` method:
1. Queries PathSystem for segments in this chunk
2. Creates visual mesh for path segments
3. Detects and handles path endpoints

### World Manager Integration

The starting location is created and managed by WorldManager:

```gdscript
# In world_manager.gd _ready() function
starting_location = StartingLocation.new()
add_child(starting_location)

# After chunk loading
starting_location.adjust_to_terrain(self)
```

## Configuration / Konfiguration

### Path Constants (in path_system.gd)

```gdscript
const DEFAULT_PATH_WIDTH = 2.5          # Path width in world units (increased for visibility)
const BRANCH_PROBABILITY = 0.15         # 15% chance to branch
const ENDPOINT_PROBABILITY = 0.05       # 5% chance to end randomly
const MIN_SEGMENT_LENGTH = 8.0          # Minimum segment length
const MAX_SEGMENT_LENGTH = 20.0         # Maximum segment length
const PATH_ROUGHNESS = 0.3              # Path curvature (0-1)
```

### Starting Location Constants (in starting_location.gd)

```gdscript
const LOCATION_RADIUS = 8.0             # Radius of starting area
const NUM_MARKER_STONES = 6             # Number of standing stones
```

## Usage Examples / Verwendungsbeispiele

### Get Path Segments for a Chunk

```gdscript
var chunk_pos = Vector2i(0, 0)
var world_seed = 12345
var segments = PathSystem.get_path_segments_for_chunk(chunk_pos, world_seed)

for segment in segments:
    print("Segment ", segment.segment_id, " type: ", segment.path_type)
    print("  From: ", segment.start_pos, " To: ", segment.end_pos)
    print("  Is endpoint: ", segment.is_endpoint)
```

### Check If Position Is On a Path

```gdscript
func is_on_path(world_pos: Vector2) -> bool:
    var chunk_x = int(floor(world_pos.x / PathSystem.CHUNK_SIZE))
    var chunk_y = int(floor(world_pos.y / PathSystem.CHUNK_SIZE))
    var chunk_pos = Vector2i(chunk_x, chunk_y)
    
    var segments = PathSystem.get_path_segments_for_chunk(chunk_pos, world_seed)
    
    for segment in segments:
        # Check if world_pos is near segment
        # ... distance calculation ...
    
    return false
```

### Manually Create Starting Location

```gdscript
var starting_loc = StartingLocation.new()
add_child(starting_loc)
starting_loc.generate_starting_location()
starting_loc.adjust_to_terrain(world_manager)
```

## Path Generation Algorithm

### Main Path Generation (Chunk 0,0)

1. Start from starting location at world origin (0, 0)
2. Generate random direction
3. Create segment with random length (14-20 units for visibility)
4. Continue in neighboring chunks

### Path Continuation

For each chunk:
1. Check all 4 neighboring chunks
2. Find segments that exit toward current chunk
3. Create corresponding entry segment
4. Add random direction variation

### Branching Logic

For each main path segment:
1. Random check against BRANCH_PROBABILITY
2. Find nearest forest or settlement cluster
3. Calculate direction toward cluster
4. Blend perpendicular and cluster direction
5. Create branch segment with appropriate type

### Endpoint Detection

A path becomes an endpoint if:
- Near a forest cluster (within radius)
- Near a settlement cluster (within radius)
- Random chance (ENDPOINT_PROBABILITY)

## Visual Appearance / Visuelle Darstellung

### Path Colors (Updated for Better Visibility)

- **Main Path**: `Color(0.75, 0.7, 0.55)` - Light tan/beige (was 0.55, 0.5, 0.4)
- **Branch**: `Color(0.65, 0.55, 0.4)` - Lighter dirt/sand (was 0.5, 0.45, 0.35)
- **Endpoint**: `Color(0.8, 0.65, 0.4)` - Bright sandy color (was 0.6, 0.5, 0.3)

### Path Visual Properties

- **Elevation**: +0.15 units above terrain (increased from +0.05 for better visibility)
- **Width**: Default 2.5 units (increased from 1.5)
  - Main paths: 3.75 units (2.5 × 1.5)
  - Branch paths: 2.0 units (2.5 × 0.8)
- **Material**: Lower roughness (0.8 vs 0.95), shadows enabled for depth
- **Starting chunk**: Guaranteed longer path (70-100% of max length)

### Starting Location Objects

- **Cairn stones**: Gray stones (0.5-0.65 RGB) with slight variation
- **Standing stones**: Similar gray, 1.2-2.0m tall, slight random tilt
- **All objects**: Low-poly boxes with vertex colors, cast shadows

## Path Endpoints / Wegeenden

### Current Implementation

When a path endpoint is detected:
```gdscript
func _play_endpoint_sound(segment):
    print("Path endpoint reached at chunk ", chunk_x, ", chunk_z)
    # TODO: Play actual sound
```

### Future Enhancement

To add sound files:

1. **Find free sound**: Check freesound.org, OpenGameArt.org
2. **Add to project**: Place in `res://assets/sounds/`
3. **Update code**:

```gdscript
func _play_endpoint_sound(segment):
    var audio_player = AudioStreamPlayer3D.new()
    audio_player.stream = load("res://assets/sounds/path_endpoint.ogg")
    
    var world_x = chunk_x * CHUNK_SIZE + segment.end_pos.x
    var world_z = chunk_z * CHUNK_SIZE + segment.end_pos.y
    var height = get_height_at_world_pos(world_x, world_z)
    
    audio_player.position = Vector3(segment.end_pos.x, height, segment.end_pos.y)
    audio_player.max_distance = 20.0
    add_child(audio_player)
    audio_player.play()
```

### Recommended Free Sound Resources

- **Freesound.org**: CC0/CC-BY licensed sounds
- **OpenGameArt.org**: Game-ready audio
- **BBC Sound Effects**: Free for non-commercial
- **Zapsplat**: Free with attribution

Search terms: "ambience", "bell", "gong", "wind chime", "mysterious"

## Testing / Tests

### Test Suite

Run tests with:
```bash
godot --headless --path . res://tests/test_scene_path_system.tscn
```

### Test Coverage

- ✅ Path generation for starting chunk
- ✅ Path continuation across chunks
- ✅ Path branching detection
- ✅ Endpoint detection
- ✅ Seed consistency

### Manual Testing

1. Run the game
2. Move to chunk (0, 0) - observe starting location
3. Walk around - observe path generation
4. Look for brown/tan paths on terrain
5. Check console for endpoint messages

## Performance / Leistung

### Complexity

- Path generation per chunk: O(n) where n = neighboring chunks
- Path mesh creation: O(s) where s = number of segments
- Memory per segment: ~100 bytes

### Optimization Tips

1. **Reduce BRANCH_PROBABILITY** if too many paths
2. **Increase MIN_SEGMENT_LENGTH** for fewer segments
3. **Limit cluster search range** in `_find_nearest_cluster`
4. **Cache path segments** instead of regenerating

## Future Enhancements / Zukünftige Erweiterungen

### Phase 1 (Planned)

- [ ] Add actual sound files for endpoints
- [ ] Improve path terrain integration (flatten terrain slightly)
- [ ] Add path decoration (small rocks, grass patches)

### Phase 2 (Possible)

- [ ] Path quality levels (dirt → cobblestone → paved)
- [ ] Path wear based on distance from starting location
- [ ] Bridge generation for water crossings
- [ ] Path signposts at branches

### Phase 3 (Advanced)

- [ ] World characteristics system (Zeit, Epoche, Stil)
- [ ] Path style adaptation based on world characteristics
- [ ] Historical path layers (ancient roads, trade routes)
- [ ] NPC pathfinding using path network

## Troubleshooting / Fehlerbehebung

### No Paths Visible

1. Check chunk generation calls `_generate_paths()`
2. Verify PathSystem is loaded correctly
3. Check path_mesh_instance is added to scene tree
4. Verify path colors aren't too similar to terrain

### Paths Don't Continue

1. Check `_continue_paths_from_neighbors()` logic
2. Verify chunk_segments registry is working
3. Test with different world seeds

### Endpoints Not Working

1. Check ClusterSystem is available
2. Verify cluster detection logic
3. Test with higher ENDPOINT_PROBABILITY

### Starting Location Not Visible

1. Check starting_location is added to scene
2. Verify adjust_to_terrain() is called
3. Check terrain height at origin (0, 0, 0)

## API Reference / API-Referenz

### PathSystem Static Methods

```gdscript
# Get or generate path segments for a chunk
static func get_path_segments_for_chunk(chunk_pos: Vector2i, world_seed: int) -> Array[PathSegment]

# Clear all generated paths (testing)
static func clear_all_paths()

# Get total number of segments
static func get_total_segments() -> int
```

### StartingLocation Methods

```gdscript
# Generate the starting location objects
func generate_starting_location()

# Adjust object heights to terrain
func adjust_to_terrain(world_manager)

# Get world position of starting location
func get_world_position() -> Vector3
```

## Integration with Existing Systems

### Cluster System

Paths intelligently target existing forest and settlement clusters:
- Branch paths aim toward nearby clusters
- Paths end when reaching cluster boundaries
- Different path types for forest vs. village

### Narrative System

Future integration possibilities:
- Narrative markers at path intersections
- Quest hooks for path exploration
- Story elements at path endpoints

### Terrain System

Paths adapt to terrain:
- Follow terrain height with small offset (+0.05)
- Avoid steep slopes (future enhancement)
- Respect water bodies (future enhancement)

## Files Modified / Geänderte Dateien

### New Files

- `scripts/path_system.gd` - Path generation system
- `scripts/starting_location.gd` - Starting location objects
- `tests/test_path_system.gd` - Test suite
- `tests/test_scene_path_system.tscn` - Test scene
- `PATH_SYSTEM.md` - This documentation

### Modified Files

- `scripts/chunk.gd` - Added path generation and rendering (updated for visibility)
- `scripts/world_manager.gd` - Added starting location
- `scripts/path_system.gd` - Path generation logic (updated for visibility)
- `PATH_SYSTEM.md` - This documentation (updated)
- `tests/verify_path_visibility.gd` - Verification script (new)

## Recent Changes / Letzte Änderungen

### January 2026 - Starting Path Position Fix

**Problem**: The path in the starting chunk was not visible from the starting location marker.

**Root Cause**: The starting location marker (central cairn) is at world position (0, 0, 0), but the path was starting from the chunk center at (16, 0, 16), creating a ~22 unit gap.

**Solution**: Modified path generation to start from position (0, 0) to align with the starting location marker.

**Files Changed**: `scripts/path_system.gd`

### January 2026 - Visibility Improvements

**Problem**: Paths were not visible enough in the game world.

**Solution**: Multiple improvements to make paths stand out:
1. **Brighter colors**: Main paths now use light tan/beige instead of dark brown
2. **Increased elevation**: Paths now sit +0.15 units above terrain (was +0.05)
3. **Wider paths**: Default width increased from 1.5 to 2.5 units
4. **Better materials**: Reduced roughness and enabled shadow casting
5. **Guaranteed visibility**: Starting chunk always has a longer initial path

These changes make paths clearly visible against the terrain while maintaining a natural appearance.

## License / Lizenz

Same as main project.

---

**Version**: 1.0  
**Date**: January 2026  
**Status**: ✅ Core implementation complete, sound files deferred
