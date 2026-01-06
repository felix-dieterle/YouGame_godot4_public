# YouGame - Development Documentation

## Project Overview

YouGame is a procedurally generated 3D game built with Godot 4, featuring dynamic terrain generation, chunk-based world management, and NPC systems optimized for Android devices.

## Project Structure

```
YouGame_godot4/
├── .github/
│   └── workflows/
│       └── build.yml          # CI/CD pipeline
├── scenes/
│   └── main.tscn              # Main game scene
├── scripts/
│   ├── chunk.gd               # Chunk generation and management
│   ├── world_manager.gd       # World chunk loading/unloading
│   ├── npc.gd                 # NPC with state machine
│   ├── narrative_marker.gd    # Narrative marker system
│   ├── quest_hook_system.gd   # Quest generation from markers
│   └── debug_visualization.gd # Debug tools
├── assets/
│   ├── models/                # 3D models
│   └── textures/              # Textures
├── tests/
│   ├── test_chunk.gd          # Chunk tests
│   └── test_scene.tscn        # Test runner scene
├── project.godot              # Godot project configuration
├── export_presets.cfg         # Android export settings
├── build.sh                   # Build automation script
└── run_tests.sh               # Test runner script
```

## Core Systems

### 1. Terrain Generation

The terrain system uses seed-based noise generation to create procedural heightmaps:

- **Chunk Size**: 32x32 world units
- **Resolution**: 32x32 cells per chunk
- **Height Variation**: ±10 units using Perlin noise
- **Seed-based**: Reproducible terrain generation

### 2. Chunk Management

The WorldManager handles dynamic chunk loading:

- **View Distance**: 3 chunks in each direction
- **Dynamic Loading**: Chunks load/unload based on player position
- **Memory Efficient**: Only active chunks are kept in memory

### 3. Walkability System

Each chunk calculates walkability:

- **Slope Calculation**: Per-cell slope analysis
- **Walkable Threshold**: ≤30° slope angle
- **Minimum Coverage**: 80% of chunk must be walkable
- **Auto-smoothing**: Terrain smooths if walkability is insufficient

### 4. NPC System

Simple state machine for NPCs:

- **States**: Idle, Walk
- **Terrain Following**: NPCs snap to terrain height
- **Random Movement**: NPCs walk in random directions

### 5. Narrative System

Quest hooks and markers:

- **Marker Types**: Discovery, Encounter, Landmark
- **Dynamic Quests**: Generated from markers
- **Importance Weighting**: Markers have importance values

## Building the Project

### Prerequisites

- Godot 4.3 or later
- Android SDK (for Android builds)
- JDK 17 (for Android builds)

### Running Tests

```bash
./run_tests.sh
```

Or manually:
```bash
godot --headless res://tests/test_scene.tscn
```

### Building for Android

```bash
./build.sh
```

The APK will be created in `export/YouGame.apk`

## Testing

The project includes automated tests for:

1. **Seed Reproducibility**: Verifies same seed produces identical terrain
2. **Walkability**: Ensures chunks meet minimum walkability requirements

## Performance Optimizations

For Android devices:

- Mobile rendering method (GL Compatibility)
- MSAA 3D anti-aliasing
- Low-poly terrain meshes
- Efficient chunk culling
- Minimal per-frame calculations

## Debug Features

- Chunk border visualization (yellow lines)
- Walkability visualization (green = walkable, red = not walkable)

Toggle with debug visualization system.

## Future Enhancements

As outlined in the README:

- [ ] LOD (Level of Detail) system
- [ ] Mesh instancing for assets
- [ ] Advanced biome system
- [ ] Flood-fill connectivity checks
- [ ] Edge blending between chunks
- [ ] More complex NPC behaviors
- [ ] Story generation system

## Contributing

1. Follow GDScript style conventions
2. Run tests before committing
3. Ensure Android compatibility
4. Document new features

## License

See project repository for license information.
