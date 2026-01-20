# YouGame

A procedurally generated 3D exploration game built with Godot 4.3, optimized for Android devices.

## Overview

YouGame is a mobile-first procedural 3D game featuring:
- **Dynamic chunk-based terrain generation** with seed-based reproducibility
- **Intelligent walkability system** ensuring playable terrain
- **Cross-chunk systems** for paths, objects, and narrative elements
- **Day/night cycle** with weather effects
- **Save/load system** for persistent gameplay
- **Mobile-optimized controls** with on-screen joysticks
- **Debug tools** for development and testing

**Current Version:** 1.0.52  
**Engine:** Godot 4.3  
**Target Platform:** Android (arm64-v8a)  
**Rendering:** Mobile/GL Compatibility mode

## Quick Start

### For Players

1. **Download** the APK from releases
2. **Install** on your Android device
3. **Play** - Use on-screen joysticks to move and look around
4. **Toggle camera** with the V key (if using keyboard)

### For Developers

```bash
# Clone the repository
git clone <repository-url>

# Open in Godot 4.3
godot project.godot

# Run tests
./run_tests.sh

# Build for Android
./build.sh
```

See **[QUICKSTART.md](QUICKSTART.md)** for detailed setup instructions.

## Documentation

### 📖 Essential Reading

- **[QUICKSTART.md](QUICKSTART.md)** - Setup and first run
- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Development practices and build instructions
- **[FEATURES.md](FEATURES.md)** - Complete feature list
- **[docs/INDEX.md](docs/INDEX.md)** - Complete documentation index

### 🤖 For AI Agents

**Start here for AI-assisted development:**

- **[.github/instructions/PROJECT_GUIDE.md](.github/instructions/PROJECT_GUIDE.md)** - Comprehensive guide optimized for AI agents
  - Architecture overview and patterns
  - Code conventions and best practices
  - Performance guidelines
  - Common tasks and examples

### 💻 Code Documentation

- **[scripts/README.md](scripts/README.md)** - Complete guide to all scripts (21 files)
  - System architecture
  - Key algorithms
  - Code patterns
  - Extension examples

### 🔧 System Documentation

Detailed documentation for each major system in [docs/systems/](docs/systems/):

- [Terrain Generation](docs/systems/TERRAIN_RENDERING.md)
- [Cluster System](docs/systems/CLUSTER_SYSTEM.md)
- [Path System](docs/systems/PATH_SYSTEM.md)
- [Narrative System](docs/systems/NARRATIVE_SYSTEM.md)
- [Day/Night Cycle](docs/systems/DAY_NIGHT_CYCLE.md)
- [Save/Load System](docs/systems/SAVE_LOAD_SYSTEM.md)
- [Debug Overlay](docs/systems/DEBUG_OVERLAY_SYSTEM.md)

## Core Features

### Procedural Terrain Generation
- Seed-based reproducible terrain using Perlin noise
- Chunk-based world with dynamic loading/unloading
- Automatic edge blending between chunks
- Walkability calculation (≤30° slope)
- Guaranteed 80% walkable terrain per chunk
- Multiple biomes (grassland, forest, rocky, mountain, ocean)
- Ocean biome with multi-chunk seas
- Coastal lighthouses at regular intervals

### World Systems
- **Cluster System:** Cross-chunk object placement (trees, buildings)
- **Path System:** Connected paths between points of interest
- **Narrative System:** Dynamic quest markers and points of interest
- **Day/Night Cycle:** Dynamic lighting and sky transitions
- **Weather System:** Weather effects integrated with time of day
- **Ocean System:** Large bodies of water spanning multiple chunks with lighthouses

### Player Experience
- Third-person and first-person camera modes
- Smooth terrain following
- Mobile joystick controls
- Keyboard/mouse support for desktop
- Save/load game state
- Debug overlay with performance info

### Technical Features
- Mobile-optimized rendering (GL Compatibility)
- Low-poly procedural models (trees, rocks, buildings)
- Efficient chunk management (only active chunks in memory)
- Automated testing for seed reproducibility
- Android APK build automation

## Project Structure

```
YouGame_godot4_public/
├── .github/
│   ├── instructions/       # AI agent guides
│   └── workflows/          # CI/CD
├── scenes/                 # Godot scene files
│   └── main.tscn          # Main game scene
├── scripts/               # GDScript source (21 files)
│   ├── world_manager.gd   # Chunk loading/unloading
│   ├── chunk.gd           # Terrain generation
│   └── ...                # See scripts/README.md
├── assets/               # 3D models, textures, audio
├── tests/               # Automated tests
├── docs/                # Documentation
│   ├── systems/         # System-specific docs
│   ├── archive/         # Historical notes
│   └── INDEX.md        # Documentation index
├── project.godot        # Project configuration
├── export_presets.cfg   # Android export settings
├── build.sh            # Build script
└── run_tests.sh        # Test runner
```

## Development

### Requirements

- Godot 4.3 or later
- Android SDK (for Android builds)
- JDK 17 (for Android builds)

### Building

```bash
# Run tests
./run_tests.sh

# Build for Android
./build.sh
# Output: export/YouGame.apk
```

### Code Conventions

- **Language:** GDScript with strict type hints
- **Style:** snake_case for variables/functions, SCREAMING_SNAKE_CASE for constants
- **Performance:** Mobile-first optimization (no heavy operations in _process())
- **Testing:** Automated tests for core functionality

See [DEVELOPMENT.md](DEVELOPMENT.md) for complete development guidelines.

## Key Systems

### World Management
The `WorldManager` dynamically loads and unloads 32×32 world unit chunks based on player position. Each chunk generates procedural terrain using seed-based noise, ensuring reproducibility.

### Terrain Generation
Each `Chunk` creates a 32×32 cell heightmap, calculates walkability based on slope (≤30°), and ensures minimum 80% walkable area through automatic smoothing if needed.

### Cross-Chunk Features
Systems like `ClusterSystem` and `PathSystem` coordinate object placement and path generation across chunk boundaries, maintaining consistency in the procedural world.

## Performance

**Optimized for Android:**
- Mobile rendering method (GL Compatibility)
- MSAA 3D anti-aliasing
- Low-poly meshes (trees, rocks, buildings)
- Efficient chunk culling
- Minimal per-frame calculations
- Memory-efficient chunk management

**Target:** 60 FPS on mid-range Android devices

## Testing

```bash
# Run all tests
./run_tests.sh

# Or manually
godot --headless res://tests/test_scene.tscn
```

**Test Coverage:**
- Seed reproducibility
- Walkability requirements (80% threshold)
- Chunk loading/unloading
- Save/load functionality

## Contributing

1. Review [DEVELOPMENT.md](DEVELOPMENT.md) for guidelines
2. Follow GDScript style conventions
3. Run tests before committing
4. Ensure Android compatibility
5. Update relevant documentation

## License

See repository for license information.

## Links

- **Documentation Index:** [docs/INDEX.md](docs/INDEX.md)
- **AI Agent Guide:** [.github/instructions/PROJECT_GUIDE.md](.github/instructions/PROJECT_GUIDE.md)
- **Scripts Reference:** [scripts/README.md](scripts/README.md)
- **Godot Docs:** https://docs.godotengine.org/

---

**Version:** 1.0.52  
**Last Updated:** 2026-01-15  
**Engine:** Godot 4.3