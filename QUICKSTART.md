# Quick Start Guide

Welcome to YouGame! This guide will help you get started with the project.

## Prerequisites

- **Godot Engine**: Version 4.3 or later
  - Download from: https://godotengine.org/download
  - For headless testing/building: Install godot-headless or godot4

For Android development (optional):
- **Android SDK**: API Level 21+ (Android 5.0+)
- **Java JDK**: Version 17 or later
- **Android Export Templates**: Installed via Godot

## Opening the Project

1. **Launch Godot Engine**
2. **Click "Import"**
3. **Browse to the project folder**
4. **Select `project.godot`**
5. **Click "Import & Edit"**

## Running the Game

### In Godot Editor
1. Press **F5** or click the **Play** button
2. The game will generate procedural terrain around the camera
3. Terrain will be colored:
   - **Green** = Walkable areas (≤30° slope)
   - **Red** = Steep/non-walkable areas

### From Command Line
```bash
godot --path . scenes/main.tscn
```

## Running Tests

### Using the Test Script
```bash
chmod +x run_tests.sh
./run_tests.sh
```

### Manually
```bash
godot --headless --path . res://tests/test_scene.tscn
```

### Expected Test Output
```
=== Starting Chunk Tests ===

--- Test: Seed Reproducibility ---
PASS: Chunks with same seed produce identical terrain

--- Test: Walkability Percentage ---
PASS: Chunk (0, 0) has XX.XX% walkable area
PASS: Chunk (1, 1) has XX.XX% walkable area
...
PASS: All chunks meet minimum walkability requirement

=== All Tests Completed ===
```

## Building for Android

### Prerequisites
1. Install Android SDK and set `ANDROID_SDK_ROOT` environment variable
2. Install Java JDK 17+
3. Download Android export templates in Godot
4. **Create a debug keystore** (for testing) or use a release keystore (for distribution)

### Setting Up Android Keystore

Android requires all APKs to be signed. For development/testing, Godot will use a debug keystore automatically if no custom keystore is specified.

#### Option 1: Use Godot's Debug Keystore (Recommended for Testing)
Godot will automatically generate and use a debug keystore. No additional setup needed!

**Important**: The keystore fields in `export_presets.cfg` should remain empty for debug builds - Godot handles everything automatically.

#### Option 2: Create Your Own Keystore (For Distribution)
```bash
# Create a release keystore (valid for 25 years - Google Play Store requirement)
keytool -genkeypair -v -keystore YouGame-release.keystore -alias yougame \
  -keyalg RSA -keysize 2048 -validity 9125

# Enter passwords and information when prompted
```

Then in Godot Editor:
1. Go to **Project → Export**
2. Select the **Android** preset
3. Under **Keystore**, set:
   - **Release**: Path to your `.keystore` file
   - **Release User**: Your alias (e.g., `yougame`)
   - **Release Password**: Your keystore password

**Note**: Never commit your keystore or passwords to version control!

### Build Command
```bash
chmod +x build.sh
./build.sh
```

The APK will be created at: `export/YouGame.apk`

### Manual Build
```bash
# For debug build (uses debug keystore automatically)
godot --headless --export-debug "Android" export/YouGame-debug.apk

# For release build (requires keystore configuration)
godot --headless --export-release "Android" export/YouGame.apk
```

## Adding a Player Character

The project includes a player controller. To enable it:

1. Open `scenes/main.tscn` in Godot
2. Right-click on the root node → Add Child Node
3. Add a **CharacterBody3D** node
4. Name it "Player"
5. Select the Player node
6. In the Inspector, click the script icon → Load
7. Select `scripts/player.gd`
8. Save the scene

**Controls:**
- **Arrow Keys** or **WASD**: Move
- **Mouse Wheel**: Zoom camera in/out

## Adding NPCs

1. In the scene tree, right-click → Add Child Node
2. Add a **CharacterBody3D** node
3. Attach `scripts/npc.gd` script
4. Position the NPC in the world
5. Run the game - NPC will automatically:
   - Follow the terrain height
   - Switch between Idle and Walk states
   - Move randomly when walking

## Project Structure

```
YouGame_godot4/
├── scenes/           # Game scenes
├── scripts/          # GDScript files
├── assets/           # 3D models, textures (add your own)
├── tests/            # Automated tests
├── build.sh          # Build automation
├── run_tests.sh      # Test automation
└── *.md              # Documentation
```

## Understanding the Systems

### Terrain Generation
- Chunks are **32x32 world units**
- Each chunk has **32x32 cells**
- Height generated using **Perlin noise**
- Same seed = same terrain (reproducible)

### Chunk Loading
- Chunks load dynamically around the camera/player
- **View distance**: 3 chunks in each direction
- Total active area: **7x7 chunk grid**
- Distant chunks unload automatically

### Walkability
- Calculated per cell based on slope
- **Green areas**: ≤30° slope (walkable)
- **Red areas**: >30° slope (steep)
- Minimum 80% of each chunk must be walkable
- Auto-smoothing if requirement not met

### Metadata System
Each chunk stores:
- **Biome**: Type of terrain (currently "grassland")
- **Openness**: 0 (closed/forest) to 1 (open/plains)
- **Landmark Type**: "hill", "valley", or empty

### Quest System
- **Narrative Markers**: Points of interest in the world
- **Quest Hooks**: Generate quests from markers
- Types: Discovery, Encounter, Landmark

## Running the Narrative Marker Demo

The project includes a demo mode to showcase the narrative marker and quest hook system:

### Option 1: Demo Scene (Recommended)
```bash
# Run the demo scene
godot --path . scenes/demo_narrative.tscn
```

This will:
1. Generate terrain with narrative markers
2. Automatically enable demo mode after 2 seconds
3. Print marker summary to console
4. Create a demo quest with generated story elements
5. Track player progress toward quest objectives

### Option 2: Enable Demo in Main Scene
Add the `NarrativeDemo` node to `scenes/main.tscn`:

1. Open `scenes/main.tscn` in Godot
2. Right-click on the root node → Add Child Node
3. Add a **Node** and name it "NarrativeDemo"
4. Attach the script `scripts/narrative_demo.gd`
5. Save and run the scene

### Expected Demo Output
```
========================================
NARRATIVE MARKER DEMO MODE ACTIVATED
========================================

QuestHookSystem: 12 markers available
  - marker_0_0_0 (type: discovery, importance: 0.50) at (15.3, 2.1, 18.7)
  - marker_1_1_0 (type: landmark, importance: 0.80) at (45.2, 8.3, 52.1)
  ...

--- Creating new demo quest ---
Quest created successfully!
Quest ID: demo_quest_123456789
Title: Demo Quest: Journey Through the Land
Number of objectives: 3
  Objective 1: Explore the unknown area in the grassland near the elevated hill...
  Objective 2: Meet someone at this location in the grassland (open terrain)...
  Objective 3: Investigate the mysterious location in the grassland...
```

### Understanding the Demo
- **Markers** are generated automatically based on chunk metadata (biome, landmark, openness)
- **No fixed story text** - stories are generated from flexible metadata
- **Quests** automatically select 1-3 markers as objectives
- **Demo mode** showcases dummy story element generation
- **Mobile-optimized** - lightweight marker generation (~200 bytes per marker)

For more details, see `NARRATIVE_SYSTEM.md`

## Debugging

### Enable Debug Visualizations
In `scenes/main.tscn`, the DebugVisualization node is already set up.

**Toggle options:**
- `show_chunk_borders`: Yellow lines around chunks
- `show_walkability`: Green/red vertex colors (always on)

### Viewing Chunk Data
In a script, access chunk data:
```gdscript
var world_manager = get_tree().get_first_node_in_group("WorldManager")
var chunk = world_manager.get_chunk_at_position(Vector3(10, 0, 10))
if chunk:
    print("Biome: ", chunk.biome)
    print("Openness: ", chunk.openness)
    print("Landmark: ", chunk.landmark_type)
```

## Performance Tips

### For Desktop
- The game uses mobile renderer for compatibility
- Can switch to Forward+ renderer in project settings for better visuals

### For Android
- Already optimized with:
  - Mobile GL compatibility renderer
  - MSAA 3D anti-aliasing
  - Efficient mesh generation
  - Dynamic chunk culling

### Improving Performance
1. Reduce `VIEW_DISTANCE` in `world_manager.gd`
2. Lower chunk `RESOLUTION` in `chunk.gd`
3. Disable debug visualizations in production

## Next Steps

### Adding Content
1. **3D Models**: Place in `assets/models/`
2. **Textures**: Place in `assets/textures/`
3. **More Biomes**: Extend `chunk.gd` metadata system
4. **Advanced NPCs**: Add pathfinding and behaviors to `npc.gd`

### Expanding Features
- Implement full flood-fill connectivity checks
- Add asset placement based on walkability
- Create story generation from narrative markers
- Implement LOD (Level of Detail) for distant chunks
- Add multiplayer support

## Troubleshooting

### "Godot not found"
- Install Godot 4.3+ and ensure it's in your PATH
- Or edit `build.sh` and `run_tests.sh` to point to your Godot executable

### "Export template not found"
- Open Godot Editor
- Go to Editor → Manage Export Templates
- Download templates for your Godot version

### "Package invalid" when installing APK on Android
This error occurs when the APK is not properly signed. **Solution:**

1. **For testing/development**: Use debug build (automatically signed)
   ```bash
   ./build.sh
   # or
   godot --headless --export-debug "Android" export/YouGame-debug.apk
   ```

2. **For release**: Configure a keystore in Godot Editor
   - Project → Export → Android → Keystore section
   - See "Building for Android" section above for keystore setup

3. **Verify package signing is enabled** in `export_presets.cfg`:
   - `package/signed=true`

### Terrain not generating
- Check console for errors
- Verify `world_manager.gd` is attached to WorldManager node
- Ensure main scene is `scenes/main.tscn`

### Tests failing
- Verify all script files are in `scripts/` folder
- Check that `chunk.gd` is properly saved
- Run from project root directory

## Resources

### Documentation
- `DEVELOPMENT.md`: Development guide
- `IMPLEMENTATION.md`: Requirements mapping
- `PROJECT_SUMMARY.md`: Complete overview
- `scripts/README.md`: Code architecture

### External Links
- Godot Documentation: https://docs.godotengine.org/
- GDScript Guide: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/
- Godot Asset Library: https://godotengine.org/asset-library/

## Support

For issues or questions:
1. Check the documentation files
2. Review the code comments
3. Check Godot documentation
4. Open an issue on GitHub

---

**Happy Developing!** 🎮
