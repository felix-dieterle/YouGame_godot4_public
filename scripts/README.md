# Scripts Architecture

## Quick Reference - All Scripts (21 files)

### Core Systems (5 files)
- **world_manager.gd** - Chunk loading/unloading manager (WorldManager class)
- **chunk.gd** - Procedural terrain generation (Chunk class)
- **cluster_system.gd** - Cross-chunk object placement (ClusterSystem class)
- **path_system.gd** - Path network generation (PathSystem class)
- **starting_location.gd** - Player spawn point manager (StartingLocation class)

### Player & Controls (2 files)
- **player.gd** - Player character controller with dual camera (Player class)
- **mobile_controls.gd** - On-screen joystick controls for mobile

### NPC & Narrative (4 files)
- **npc.gd** - NPC AI with state machine (NPC class)
- **narrative_marker.gd** - Points of interest markers (NarrativeMarker class)
- **quest_hook_system.gd** - Dynamic quest generation (QuestHookSystem class)
- **narrative_demo.gd** - Narrative system demo/test

### Environment (3 files)
- **day_night_cycle.gd** - Time of day and lighting (DayNightCycle class)
- **weather_system.gd** - Weather effects (WeatherSystem class)
- **procedural_models.gd** - Runtime 3D model generation (ProceduralModels class)

### UI & Debug (6 files)
- **ui_manager.gd** - Main UI controller
- **pause_menu.gd** - Pause menu system
- **debug_log_overlay.gd** - Debug logging UI (Autoload)
- **debug_visualization.gd** - Visual debugging tools
- **debug_narrative_ui.gd** - Narrative system debug UI
- **ruler_overlay.gd** - Distance measurement tool

### Save/Load (1 file)
- **save_game_manager.gd** - Save/load system (Autoload)

## Key Constants by File

### world_manager.gd
- `CHUNK_SIZE = 32` - World units per chunk side
- `VIEW_DISTANCE = 3` - Chunks to load in each direction
- `WORLD_SEED = 12345` - Default world generation seed

### chunk.gd
- `CHUNK_SIZE = 32` - Same as WorldManager
- `RESOLUTION = 32` - Grid cells per chunk side (1 cell = 1 world unit)
- `CELL_SIZE = 1.0` - World units per cell
- `MAX_SLOPE_WALKABLE = 30.0` - Maximum walkable slope (degrees)
- `MIN_WALKABLE_PERCENTAGE = 0.8` - Minimum required walkable area
- `HEIGHT_RANGE = 10.0` - Maximum height variation (±10 units)

### npc.gd
- `WALK_SPEED = 2.0` - NPC movement speed
- `IDLE_TIME_MIN/MAX` - Random idle duration range

## Autoload Singletons

These scripts are globally accessible:

**DebugLogOverlay** (`debug_log_overlay.gd`)
```gdscript
DebugLogOverlay.log_message("Your debug message")
```

**SaveGameManager** (`save_game_manager.gd`)
```gdscript
SaveGameManager.save_game()
SaveGameManager.load_game()
```

## Scene Hierarchy

```
Main Scene (scenes/main.tscn)
├── WorldManager (world_manager.gd)
│   ├── Chunk_0_0 (chunk.gd) - dynamically loaded
│   │   ├── MeshInstance3D (terrain)
│   │   ├── MeshInstance3D (water) [optional]
│   │   ├── MeshInstance3D (paths) [optional]
│   │   └── StaticBody3D[] (rocks, trees)
│   └── StartingLocation (starting_location.gd)
├── Player (player.gd)
│   ├── Camera3D (third person, always active)
│   └── Camera3D (first person, toggled)
├── ClusterSystem (cluster_system.gd)
├── PathSystem (path_system.gd)
├── QuestHookSystem (quest_hook_system.gd)
├── DayNightCycle (day_night_cycle.gd)
│   ├── DirectionalLight3D (sun)
│   └── WorldEnvironment (sky)
├── WeatherSystem (weather_system.gd)
├── UIManager (ui_manager.gd)
│   ├── Version Label
│   ├── Loading Message
│   ├── Time Speed Controls
│   └── Pause Menu (pause_menu.gd)
└── MobileControls (mobile_controls.gd)
    ├── Left Joystick
    └── Right Joystick
```

## Data Flow Patterns

### 1. Chunk Loading Cycle
```
Player moves → WorldManager detects position change → 
Calculate required chunks → Load missing chunks → 
Each Chunk generates terrain → Unload distant chunks
```

### 2. Terrain Generation Pipeline (chunk.gd)
```
_setup_noise() → _generate_heightmap() → 
_calculate_walkability() → _ensure_walkable_area() → 
_calculate_metadata() → _generate_narrative_markers() → 
_generate_lake_if_valley() → _create_mesh() → 
_place_rocks() → _place_cluster_objects() → _generate_paths()
```

### 3. Cross-Chunk Systems
```
ClusterSystem coordinates tree/building placement →
PathSystem generates connected paths →
Chunks request data from coordinators →
Coordinators return chunk-specific segments
```

### 4. Save/Load Flow
```
User triggers save → SaveGameManager collects data →
Player position, camera mode, world seed saved to JSON →
On load: JSON parsed → World recreated with seed →
Player position restored
```

### 5. NPC Behavior Loop
```
_process() → Update state machine → 
If Walking: move forward, terrain snap → 
If Idle: wait for timer → Switch states randomly
```

## Key Algorithms & Implementation Details

### Terrain Generation (chunk.gd)
1. Initialize FastNoiseLite with world seed
2. Sample noise at (chunk_x * CHUNK_SIZE + local_x, chunk_z * CHUNK_SIZE + local_z)
3. Generate heightmap: base_height = noise * HEIGHT_RANGE
4. Blend edges with neighboring chunks (if loaded)
5. Calculate slopes: max_height_diff between cell corners
6. Mark cells with slope ≤ 30° as walkable
7. Count walkable percentage, smooth if < 80%
8. Build mesh using SurfaceTool with vertex colors

### Chunk Loading (world_manager.gd)
1. In _process(): Get player world position
2. Convert to chunk coordinates: int(floor(pos / CHUNK_SIZE))
3. Compare with previous player_chunk
4. If changed: determine chunks in VIEW_DISTANCE range
5. Load missing chunks (create Chunk instance, call generate(), add to scene)
6. Unload distant chunks (queue_free(), remove from chunks dict)
7. Maintain chunks dictionary keyed by Vector2i(chunk_x, chunk_z)

### Walkability Check (chunk.gd)
1. For each cell (i, j) in RESOLUTION × RESOLUTION grid
2. Get heights at 4 corners: h0, h1, h2, h3
3. Calculate max_diff = max(h0, h1, h2, h3) - min(h0, h1, h2, h3)
4. Convert to slope: angle = atan(max_diff / CELL_SIZE) * 180 / PI
5. If angle ≤ MAX_SLOPE_WALKABLE: mark cell as walkable
6. Count walkable cells, calculate percentage
7. If < MIN_WALKABLE_PERCENTAGE: apply smoothing algorithm

### Path Generation (path_system.gd)
1. Identify endpoints (narrative markers, settlements)
2. Calculate shortest path using A* or simple line
3. Subdivide path into chunks
4. For each chunk: create PathSegment with local coordinates
5. Chunks render paths as ground texture overlays

### Cluster Object Placement (cluster_system.gd)
1. Define clusters with center point and radius
2. For each cluster affecting a chunk:
3. Generate random positions within cluster area
4. Filter positions: must be in chunk bounds and walkable
5. Create procedural model (tree, building, rock)
6. Place at terrain height
7. Add to chunk's placed_objects array

## Code Style Patterns

### Type Hints (Required)
```gdscript
# Variables
var player_chunk: Vector2i = Vector2i(0, 0)
var chunks: Dictionary = {}  # Keys: Vector2i, Values: Chunk

# Functions
func get_height_at(x: float, z: float) -> float:
    return heightmap[index]
```

### Null Safety
```gdscript
var player = get_parent().get_node_or_null("Player")
if not player:
    push_warning("Player not found")
    return
```

### Resource Management
```gdscript
# Free chunks properly
func _unload_chunk(chunk_pos: Vector2i):
    if chunks.has(chunk_pos):
        chunks[chunk_pos].queue_free()
        chunks.erase(chunk_pos)
```

### Debug Logging
```gdscript
# Use autoload for debug messages
DebugLogOverlay.log_message("Chunk %s loaded" % [chunk_pos])
```

## Performance Patterns

### Avoid in _process()
```gdscript
# ❌ BAD - Heavy operation every frame
func _process(delta):
    generate_entire_terrain()

# ✅ GOOD - Only check position changes
func _process(delta):
    var new_chunk = calculate_chunk_position()
    if new_chunk != player_chunk:
        update_chunks()
```

### Cache Frequently Used Values
```gdscript
# ❌ BAD - Recalculate every time
func get_cell_height(i, j):
    return noise.get_noise_2d(chunk_x * 32 + i, chunk_z * 32 + j) * 10

# ✅ GOOD - Pre-calculate heightmap
var heightmap: PackedFloat32Array = []  # Calculated once
func get_cell_height(i, j):
    return heightmap[i * RESOLUTION + j]
```

### Mesh Building
```gdscript
# Use SurfaceTool for efficient mesh generation
var st = SurfaceTool.new()
st.begin(Mesh.PRIMITIVE_TRIANGLES)
st.set_smooth_group(-1)  # Flat shading for low-poly look

for face in faces:
    st.set_color(color)
    st.add_vertex(vertex)
    
mesh = st.commit()
```

## Common Extension Patterns

### Adding a New Feature to Chunks
```gdscript
# 1. Add to chunk.gd generate() pipeline
func generate():
    _setup_noise()
    _generate_heightmap()
    # ... existing steps ...
    _your_new_feature()  # Add here
    _create_mesh()

# 2. Implement private method
func _your_new_feature():
    # Access chunk data
    var x = chunk_x
    var z = chunk_z
    # Modify heightmap, place objects, etc.
```

### Adding a New Autoload System
```gdscript
# 1. Create script: scripts/my_system.gd
extends Node

func global_function():
    # Implementation

# 2. Add to project.godot
[autoload]
MySystem="*res://scripts/my_system.gd"

# 3. Use anywhere
MySystem.global_function()
```

### Adding Cross-Chunk Feature
```gdscript
# 1. Create coordinator class
class_name MyFeatureSystem
extends Node

var feature_data: Dictionary = {}

func get_data_for_chunk(cx: int, cz: int) -> Array:
    # Return chunk-specific data
    pass

# 2. In WorldManager, instantiate system
var my_feature_system: MyFeatureSystem

func _ready():
    my_feature_system = MyFeatureSystem.new()
    add_child(my_feature_system)

# 3. In Chunk, request data
func _generate_my_feature():
    var data = world_manager.my_feature_system.get_data_for_chunk(chunk_x, chunk_z)
    # Use data
```

### Adding UI Element
```gdscript
# 1. Add to scene (e.g., main.tscn) via Godot editor
# 2. Reference in ui_manager.gd or relevant script
@onready var my_label = $MyLabel

func _ready():
    my_label.text = "Hello"
```

## Testing Patterns

### Unit Test Structure
```gdscript
# tests/test_my_feature.gd
extends Node

func run_test() -> bool:
    print("Testing my feature...")
    
    # Setup
    var obj = MyFeature.new()
    
    # Execute
    var result = obj.do_something()
    
    # Assert
    if result != expected_value:
        print("FAIL: Expected %s, got %s" % [expected_value, result])
        return false
    
    print("PASS")
    return true
```

### Reproducibility Test
```gdscript
# Test that same seed produces same result
func test_seed_reproducibility():
    var chunk1 = Chunk.new(0, 0, 12345)
    chunk1.generate()
    var height1 = chunk1.heightmap[0]
    
    var chunk2 = Chunk.new(0, 0, 12345)
    chunk2.generate()
    var height2 = chunk2.heightmap[0]
    
    assert(height1 == height2, "Same seed must produce same terrain")
```

## Debugging Tips

### Enable Visual Debugging
```gdscript
# In chunk.gd, call after generation
_create_debug_visualization()  # Shows chunk borders, walkability
```

### Log to Debug Overlay
```gdscript
DebugLogOverlay.log_message("Chunk (%d, %d) loaded with %d markers" % [chunk_x, chunk_z, markers.size()])
```

### Check Walkability Issues
```gdscript
# After generation, verify
var walkable_count = walkable_map.count(1)
var total = RESOLUTION * RESOLUTION
var percentage = float(walkable_count) / total
print("Walkability: %.2f%%" % (percentage * 100))
```

## Common Gotchas

1. **Chunk Coordinates vs World Coordinates**
   - Chunk coords: `Vector2i(chunk_x, chunk_z)` - integer grid positions
   - World coords: `Vector3(world_x, y, world_z)` - float positions
   - Conversion: `chunk_x = int(floor(world_x / CHUNK_SIZE))`

2. **Vector2i Y is Z**
   - `Vector2i.x` stores chunk X
   - `Vector2i.y` stores chunk Z (not Y!)
   - Y is height/vertical in world space

3. **Heightmap Indexing**
   - 1D array for 2D grid: `index = i * RESOLUTION + j`
   - Bounds check: `0 <= index < heightmap.size()`

4. **Mobile Performance**
   - Always test changes for performance impact
   - Use Godot profiler to check frame time
   - Target: 60 FPS on mid-range Android devices

5. **Edge Blending**
   - Chunks must request neighbor heightmap edges
   - Blend only if neighbor exists
   - Prevents visible seams between chunks

## File-Specific Notes

### world_manager.gd
- Manages chunk lifecycle
- Never create Chunks directly - let WorldManager handle it
- Chunks dictionary is the source of truth for active chunks

### chunk.gd
- Large file (~500+ lines) - most complex system
- Follow existing generate() pipeline order
- Heightmap and walkable_map are parallel arrays

### player.gd
- Dual camera system: one follows (3rd person), one attached (1st person)
- Toggle with V key
- Always snaps to terrain height

### save_game_manager.gd
- Autoload singleton
- Saves to `user://savegame.json`
- Includes version info for compatibility checking

### procedural_models.gd
- Static utility class (all static functions)
- Generates low-poly models at runtime
- Returns MeshInstance3D ready to add to scene

## Documentation References

For detailed information, see:
- **Architecture**: `.github/instructions/PROJECT_GUIDE.md`
- **Development**: `DEVELOPMENT.md`
- **Systems**: `docs/systems/*.md`
- **Historical**: `docs/archive/*.md` (implementation notes)

---

**Last Updated:** 2026-01-15  
**Total Scripts:** 21  
**Godot Version:** 4.3  
**Target Platform:** Android (arm64-v8a)
