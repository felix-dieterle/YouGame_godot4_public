# World Generation Systems

Core systems for procedural world generation and management.

## Files

### World Manager (`world_manager.gd`)
- Manages chunk loading/unloading based on player position
- Maintains active chunks dictionary
- Coordinates cross-chunk systems
- Constants: `CHUNK_SIZE = 32`, `VIEW_DISTANCE = 3`, `WORLD_SEED = 12345`

### Chunk (`chunk.gd`)
- Procedural terrain generation for 32×32 world unit chunks
- Heightmap generation using Perlin noise
- Walkability analysis (≤30° slope, 80% minimum)
- Edge blending with neighboring chunks
- Object placement (rocks, trees, buildings)
- Lake generation in valley biomes
- Largest and most complex system (~4000+ lines)

### Cluster System (`cluster_system.gd`)
- Cross-chunk object placement (forests, settlements)
- Seed-based reproducibility
- Coordinates tree and building distribution
- Ensures consistent placement across chunk boundaries

### Path System (`path_system.gd`)
- Connected path network generation
- Paths from starting location with branching
- Road generation across chunks
- A* pathfinding integration

### Procedural Models (`procedural_models.gd`)
- Runtime 3D model generation
- Low-poly trees, rocks, buildings
- Static utility functions
- Returns MeshInstance3D ready for scene

### Starting Location (`starting_location.gd`)
- Player spawn point manager
- Initial spawn area with marker stones
- Coordinates starting position for new games

## Data Flow

```
Player moves → WorldManager detects → Calculate required chunks →
Load missing chunks → Each Chunk generates terrain →
Unload distant chunks
```

## Terrain Generation Pipeline

```
Chunk._setup_noise() → _generate_heightmap() →
_calculate_walkability() → _ensure_walkable_area() →
_calculate_metadata() → _generate_narrative_markers() →
_generate_lake_if_valley() → _create_mesh() →
_place_rocks() → _place_cluster_objects() → _generate_paths()
```

## Usage

```gdscript
# In main scene
var world_manager = WorldManager.new()
world_manager.world_seed = 12345
add_child(world_manager)

# Chunks are automatically managed by WorldManager
# Do not instantiate Chunk directly
```
