# YouGame - AI Agent Development Guide

## Project Overview

YouGame is a procedurally generated 3D game built with **Godot 4.3** for Android devices. It features dynamic terrain generation, chunk-based world management, and optimized performance for mobile platforms.

**Core Technology Stack:**
- Engine: Godot 4.3
- Language: GDScript
- Target Platform: Android (arm64-v8a)
- Rendering: Mobile/GL Compatibility mode
- Architecture: Chunk-based procedural generation

## Quick Start for AI Agents

### 1. Repository Structure
```
YouGame_godot4_public/
├── .github/
│   ├── instructions/       # AI agent guides (you are here)
│   └── workflows/          # CI/CD pipelines
├── scenes/                 # Godot scene files
│   └── main.tscn          # Main game scene
├── scripts/               # GDScript source files (21 files)
│   ├── world_manager.gd   # Core: Chunk loading/unloading
│   ├── chunk.gd           # Core: Terrain generation
│   ├── player.gd          # Player controller
│   ├── npc.gd            # NPC AI system
│   └── ...               # See scripts/README.md for details
├── assets/               # 3D models, textures, audio
├── tests/               # Automated test suite
├── docs/                # Documentation
│   ├── systems/         # System-specific docs
│   └── archive/         # Historical implementation notes
├── project.godot        # Godot project config (source of truth)
├── export_presets.cfg   # Android export settings
├── build.sh            # Build automation
└── run_tests.sh        # Test runner
```

### 2. Essential Files to Review First
1. `project.godot` - Project configuration and version
2. `scripts/world_manager.gd` - Understand chunk management
3. `scripts/chunk.gd` - Understand terrain generation
4. `DEVELOPMENT.md` - Development practices
5. `docs/systems/` - System documentation

### 3. Version Management
**CRITICAL:** Version number is centralized in `project.godot`:
```ini
[application]
config/version="X.Y.Z"
```

**Always update both:**
1. `project.godot` → `config/version`
2. `export_presets.cfg` → `version/name` and `version/code` (integer)

All UI displays automatically read from `ProjectSettings.get_setting("application/config/version")`.

## Architecture Overview

### Core Systems

#### 1. World Management (`world_manager.gd`)
- **Purpose:** Dynamic chunk loading/unloading based on player position
- **Key Constants:**
  - `CHUNK_SIZE = 32` (world units)
  - `VIEW_DISTANCE = 3` (chunks in each direction)
  - `WORLD_SEED = 12345` (reproducible generation)
- **Pattern:** Chunk dictionary keyed by `Vector2i(x, z)`
- **Performance:** Only active chunks in memory at once

#### 2. Terrain Generation (`chunk.gd`)
- **Purpose:** Procedural terrain using seed-based noise
- **Key Features:**
  - 32x32 cells per chunk (1x1 world unit each)
  - Height variation: ±10 units via Perlin noise
  - Walkability calculation: ≤30° slope = walkable
  - Minimum 80% walkable area (auto-smoothing if insufficient)
  - Edge blending with neighboring chunks
- **Pattern:** Each chunk self-contained but aware of neighbors

#### 3. Cluster System (`cluster_system.gd`)
- **Purpose:** Place groups of objects (trees, buildings) across chunks
- **Key Features:**
  - Cross-chunk object placement
  - Biome-aware spawning
  - Performance-optimized instancing

#### 4. NPC System (`npc.gd`)
- **States:** Idle, Walk
- **Behavior:** Simple state machine with random movement
- **Terrain Following:** NPCs snap to terrain height

#### 5. Narrative System (`narrative_marker.gd`, `quest_hook_system.gd`)
- **Purpose:** Dynamic quest generation
- **Marker Types:** Discovery, Encounter, Landmark
- **Pattern:** Markers placed during chunk generation, quests generated on-demand

#### 6. Save/Load System (`save_game_manager.gd`)
- **Autoload:** Globally accessible singleton
- **Pattern:** JSON-based save files
- **Saves:** Player position, game state, world seed

#### 7. Day/Night Cycle (`day_night_cycle.gd`, `weather_system.gd`)
- **Features:** Time progression, weather effects, sky transitions
- **Performance:** Optimized for mobile rendering

## Code Conventions & Best Practices

### GDScript Style

1. **Class Names:** Use `class_name` for reusable scripts
   ```gdscript
   extends Node3D
   class_name WorldManager
   ```

2. **Constants:** SCREAMING_SNAKE_CASE
   ```gdscript
   const CHUNK_SIZE = 32
   const VIEW_DISTANCE = 3
   ```

3. **Variables:** snake_case with type hints
   ```gdscript
   var player_chunk: Vector2i = Vector2i(0, 0)
   var chunks: Dictionary = {}
   ```

4. **Functions:** snake_case with clear names
   ```gdscript
   func _update_chunks():
       # Implementation
   ```

5. **Comments:** Use only when necessary for complex logic
   - Prefer self-documenting code
   - Add comments for non-obvious algorithms
   - Document public APIs

6. **Type Safety:** Always use type hints
   ```gdscript
   func get_height_at(x: float, z: float) -> float:
       return heightmap[index]
   ```

### Performance Guidelines

**CRITICAL for Android optimization:**

1. **Avoid Per-Frame Heavy Operations**
   - No terrain generation in `_process()`
   - Use timers or frame skipping for expensive checks
   - Cache frequently accessed values

2. **Memory Management**
   - Free unused chunks immediately
   - Use `queue_free()` for node cleanup
   - Avoid creating temporary objects in loops

3. **Rendering Optimization**
   - Use low-poly meshes
   - Enable MSAA 3D (configured in project.godot)
   - Leverage mobile rendering method (GL Compatibility)
   - Consider LOD for distant objects (future enhancement)

4. **Mesh Generation**
   - Minimize vertex count
   - Use SurfaceTool for efficient mesh building
   - Reuse materials when possible

### Error Handling

1. **Null Checks:** Always check node existence
   ```gdscript
   var player = get_parent().get_node_or_null("Player")
   if not player:
       # Handle missing player
   ```

2. **Validation:** Validate inputs and array bounds
   ```gdscript
   if index < 0 or index >= heightmap.size():
       return 0.0
   ```

3. **Debug Logging:** Use the debug overlay system
   ```gdscript
   DebugLogOverlay.log_message("Chunk loaded: %d, %d" % [x, z])
   ```

## Common Development Patterns

### 1. Adding a New Feature

**Steps:**
1. Review related system docs in `docs/systems/`
2. Check existing similar features in scripts
3. Add minimal code following existing patterns
4. Test on Android if possible (use build.sh)
5. Add debug visualization if appropriate
6. Update relevant documentation

**Example: Adding a new terrain feature**
```gdscript
# In chunk.gd, add to generate() method
func generate():
    _setup_noise()
    _generate_heightmap()
    _calculate_walkability()
    _ensure_walkable_area()
    _calculate_metadata()
    _your_new_feature()  # Add here
    _generate_narrative_markers()
    _create_mesh()
```

### 2. Debugging

**Available Tools:**
1. Debug Overlay (`debug_log_overlay.gd`) - Autoload singleton
   ```gdscript
   DebugLogOverlay.log_message("Debug info")
   ```

2. Visualization System (`debug_visualization.gd`)
   - Chunk borders (yellow lines)
   - Walkability (green/red overlay)

3. Test Suite
   ```bash
   ./run_tests.sh
   ```

**Common Issues:**
- **Terrain gaps:** Check edge blending in `_generate_heightmap()`
- **Performance drops:** Profile with Godot's built-in profiler
- **Walkability issues:** Debug with visualization overlay

### 3. Cross-Chunk Features

**Pattern for features spanning multiple chunks:**

1. **Central Coordinator:** Use WorldManager or dedicated system
2. **Chunk Registration:** Chunks report relevant data to coordinator
3. **Lazy Loading:** Generate cross-chunk data only when chunks exist

**Example: Path System**
```gdscript
# In world_manager.gd
var path_system: PathSystem

# In chunk.gd
func _generate_paths():
    if world_manager and world_manager.path_system:
        path_segments = world_manager.path_system.get_paths_for_chunk(chunk_x, chunk_z)
```

### 4. Autoload Singletons

**Current autoloads in project.godot:**
- `DebugLogOverlay` - Debug logging UI
- `SaveGameManager` - Save/load functionality

**When to add new autoload:**
- Global state management
- Cross-scene persistence
- Utility functions needed everywhere

**Pattern:**
```gdscript
# my_singleton.gd
extends Node

func my_global_function():
    # Implementation
```

Then add to project.godot:
```ini
[autoload]
MySingleton="*res://scripts/my_singleton.gd"
```

## Testing Guidelines

### Running Tests

```bash
# Run all tests
./run_tests.sh

# Or manually
godot --headless res://tests/test_scene.tscn
```

### Current Test Coverage

1. **Seed Reproducibility:** Verifies same seed → identical terrain
2. **Walkability:** Ensures 80% minimum walkable area
3. **Chunk Loading:** Tests chunk lifecycle

### Adding New Tests

**Pattern:**
```gdscript
# tests/test_my_feature.gd
extends Node

func run_test() -> bool:
    print("Testing my feature...")
    
    # Setup
    var test_object = MyFeature.new()
    
    # Execute
    var result = test_object.do_something()
    
    # Verify
    if result != expected:
        print("FAIL: Expected %s, got %s" % [expected, result])
        return false
    
    print("PASS")
    return true
```

Add to test scene and call from test runner.

## Building & Deployment

### Building for Android

```bash
./build.sh
```

**Output:** `export/YouGame.apk`

**Requirements:**
- Android SDK (configured in Godot)
- JDK 17
- Godot 4.3 CLI in PATH

**Configuration Files:**
- `export_presets.cfg` - Export settings
  - Architecture: arm64-v8a
  - Signing: Debug keystore (auto-generated)
  - Version code: Must increment for Play Store

**For Production Release:**
1. Create release keystore
2. Update export_presets.cfg with keystore path
3. Increment version code
4. Build and sign APK

## Common Tasks

### Update Game Version

1. Edit `project.godot`:
   ```ini
   [application]
   config/version="1.0.53"
   ```

2. Edit `export_presets.cfg`:
   ```ini
   [preset.0.options]
   version/name="1.0.53"
   version/code=53  # Increment integer
   ```

3. All UI displays update automatically

### Add New Script File

1. Create in `scripts/` directory
2. Follow naming convention: `feature_name.gd`
3. Add class_name if reusable: `class_name FeatureName`
4. Update `scripts/README.md` with description
5. Add to relevant scene if needed

### Modify Terrain Generation

1. Review `scripts/chunk.gd`
2. Understand `_generate_heightmap()` flow
3. Add modifications within existing noise system
4. Test with multiple seeds for reproducibility
5. Verify walkability still meets 80% threshold

### Add UI Element

1. Modify scene file (e.g., `scenes/main.tscn`)
2. Add script logic in `scripts/ui_manager.gd`
3. Ensure mobile-friendly sizing (1920x1080 viewport)
4. Test on Android if possible

## AI Agent Optimization Tips

### For Faster Navigation

1. **Use grep/glob tools:** Find code patterns quickly
   ```bash
   grep -r "CHUNK_SIZE" scripts/
   glob "**/*.gd"
   ```

2. **Start with architecture:** Read this guide, then DEVELOPMENT.md
3. **Check docs/systems/:** System-specific deep dives
4. **Reference archive:** Historical context in docs/archive/

### For Better Code Quality

1. **Follow existing patterns:** Review similar features first
2. **Type hints always:** GDScript 4.x is strongly typed
3. **Mobile-first mindset:** Android performance is priority #1
4. **Test incrementally:** Use run_tests.sh frequently
5. **Minimal changes:** Preserve existing working code

### For Avoiding Common Mistakes

1. **Don't break chunk system:** WorldManager controls chunk lifecycle
2. **Don't ignore walkability:** 80% threshold is hard requirement
3. **Don't add heavy _process():** Mobile devices have limited CPU
4. **Don't forget edge cases:** Test with different seeds
5. **Don't skip documentation:** Update relevant docs

### Understanding the Codebase Quickly

**Reading Order:**
1. This guide (PROJECT_GUIDE.md)
2. DEVELOPMENT.md (practices)
3. scripts/world_manager.gd (core system)
4. scripts/chunk.gd (core system)
5. docs/systems/ (specific systems as needed)

**Key Questions to Answer:**
- Where is feature X implemented? → grep for keywords
- How does system Y work? → Check docs/systems/Y.md
- What's the project structure? → See tree above
- What are the conventions? → See "Code Conventions" section

## Documentation Structure

**Root Level (essential only):**
- README.md - Project introduction
- DEVELOPMENT.md - Development practices
- QUICKSTART.md - Getting started guide
- FEATURES.md - Feature overview
- QUICK_REFERENCE.md - Command reference

**docs/systems/ (system deep-dives):**
- CLUSTER_SYSTEM.md
- DAY_NIGHT_CYCLE.md
- DEBUG_OVERLAY_SYSTEM.md
- NARRATIVE_SYSTEM.md
- PATH_SYSTEM.md
- SAVE_LOAD_SYSTEM.md
- TERRAIN_RENDERING.md

**docs/archive/ (historical):**
- Implementation notes from previous development
- Useful for understanding why decisions were made
- Not required reading for new features

**docs/ (supporting):**
- ASSET_GUIDE.md - Asset management
- DEBUG_README.md - Debugging tools
- MOBILE_MENU.md - Mobile UI specifics
- QUICK_SAVE.md - Save system details

## Security & Best Practices

1. **No hardcoded secrets:** Use environment variables or config files (not in git)
2. **Validate all input:** Especially from save files
3. **Sanitize user content:** If adding user-generated content features
4. **Test on device:** Android behavior differs from desktop

## Future Enhancements (Roadmap)

Planned features (not yet implemented):
- [ ] LOD (Level of Detail) system for terrain
- [ ] Mesh instancing for repeated assets
- [ ] Advanced biome system with smooth transitions
- [ ] Flood-fill connectivity checks for chunks
- [ ] More complex NPC behaviors and AI
- [ ] Procedural story generation

**When implementing these:**
1. Check if design notes exist in docs/archive/
2. Maintain mobile performance focus
3. Add tests for new functionality
4. Update relevant system documentation

## Support & Resources

**Godot 4 Documentation:**
- Official Docs: https://docs.godotengine.org/en/stable/
- GDScript Reference: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/

**Project-Specific:**
- Issues: GitHub issue tracker
- Architecture questions: Review docs/systems/
- Historical context: Check docs/archive/

## Summary

**Key Principles for AI Agents:**
1. **Mobile-first:** Every change must work on Android
2. **Performance-critical:** Avoid expensive operations
3. **Follow patterns:** Consistency with existing code
4. **Test frequently:** Use run_tests.sh
5. **Document changes:** Update relevant docs
6. **Minimal modifications:** Don't refactor working code unnecessarily

**When in Doubt:**
1. Check existing similar features
2. Review relevant system docs
3. Test on multiple scenarios
4. Ask for clarification if needed

**Success Metrics:**
- Code runs smoothly on Android devices
- Tests pass (run_tests.sh)
- No performance regressions
- Documentation updated
- Consistent with existing patterns

---

**Last Updated:** 2026-01-15
**Godot Version:** 4.3
**Project Version:** 1.0.52
