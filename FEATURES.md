# New Features

This document describes the new features added to the YouGame project.

## Sun Shadows

The DirectionalLight3D in the main scene now simulates realistic sun shadows with enhanced settings:

- **Shadow Mode**: PSSM 2 splits for better shadow quality at various distances
- **Shadow Bias**: 0.05 to prevent shadow acne
- **Shadow Blending**: Enabled for smooth transitions between shadow cascades
- **Max Distance**: 200 units to cover the visible terrain
- **Light Energy**: 1.2 for a bright, sunny atmosphere
- **Tonemap**: ACES tonemapping with 1.2 exposure for better visual quality

## Mobile Touch Controls

A virtual joystick control system has been added for mobile devices:

### Features
- **Virtual Joystick**: Positioned in the bottom-left corner
- **Visual Feedback**: Semi-transparent circular joystick with stick indicator
- **Deadzone**: 0.2 to prevent drift from small touches
- **Dual Input**: Supports both mobile touch and keyboard input (arrow keys/WASD)
- **Automatic Fallback**: Uses keyboard input when no touch is detected

### Usage
- Touch and drag the joystick area to move the player
- The player rotates to face the movement direction
- Release to stop moving

## UI Message System

A new UI system displays status messages to the player:

### Messages Displayed

1. **Initial Loading**
   - Shows "Loading terrain..." when the game starts
   - Displays "Loading complete! Ready to explore." when initial chunks are loaded
   - Message disappears after 4 seconds

2. **Chunk Generation**
   - Shows "Chunk generated: (x, z)" when new terrain chunks are created
   - Only shown after initial loading is complete
   - Message disappears after 2 seconds

### Implementation
- **UIManager**: Manages all UI elements and messages
- **Status Label**: Top-center for important messages
- **Chunk Info Label**: Top-left for chunk generation notifications

## Player System

The Player node is now fully integrated:

- **Character Body**: Uses CharacterBody3D for physics-based movement
- **Terrain Following**: Automatically snaps to terrain height
- **Camera**: Built-in camera that follows the player
- **Visual**: Blue capsule mesh for player representation
- **Movement Speed**: 5 units/second (configurable)
- **Rotation**: Smooth rotation towards movement direction

## How to Test

### Desktop
1. Open the project in Godot 4
2. Press F5 to run
3. Use arrow keys or WASD to move
4. Watch for loading messages and chunk generation notifications

### Mobile
1. Export to Android (use `./build.sh`)
2. Install the APK on your device
3. Use the virtual joystick to move
4. Touch and drag in the bottom-left area to control the player

## Technical Details

### Modified Files
- `scenes/main.tscn`: Added Player, UIManager, and MobileControls nodes; enhanced lighting
- `scripts/player.gd`: Added mobile controls support
- `scripts/world_manager.gd`: Added UI notifications for chunk generation

### New Files
- `scripts/ui_manager.gd`: UI system for messages
- `scripts/mobile_controls.gd`: Virtual joystick implementation

### Performance
- UI updates are minimal and event-driven
- Mobile controls use efficient touch event handling
- No performance impact on terrain generation

## Mobile Settings Menu

A comprehensive settings menu has been added for mobile devices:

### Features
- **Menu Button**: Positioned in the top-left corner with hamburger icon (☰)
- **Settings Panel**: Organized popup menu with sections for different settings
- **Touch-Friendly**: Large buttons optimized for mobile screens (55px height)
- **Seamless Integration**: Works with the existing mobile control system
- **Better Organization**: Grouped into Display, Audio, and Game sections
- **Enhanced Styling**: Modern look with rounded corners and distinct color schemes

### Available Settings

**Display Section:**
- **Toggle First Person View**: Switch between third-person and first-person camera views
  - Robot body automatically hides in first-person mode
  - Head bobbing effect active in first-person when moving

**Audio Section:**
- **Master Volume Control**: Slider to adjust game audio (0-100%)
  - Real-time volume adjustment
  - Visual percentage display

**Game Section:**
- **Pause Game**: Access the pause menu from mobile devices
  - Opens the main pause menu with Resume/Settings/Quit options

### Usage
- Tap the menu button (☰) in the top-left to open settings
- Adjust volume with the slider
- Select "Toggle First Person View" to switch camera modes
- Select "Pause Game" to pause the game
- Tap "✕ Close" or press the menu button again to close the settings panel

### Technical Improvements
- Increased button sizes for better touch targets
- Organized into logical sections with clear headings
- Better color differentiation between sections
- Improved spacing and padding throughout

## Terrain Biome System

The world now features distinct biome regions with varied terrain types:

### Biome Types

1. **Mountain Regions**
   - High elevation (>8.0 units)
   - Stone/rocky gray appearance transitioning to snow-covered peaks
   - **Snow Coverage**: At elevations above 12 units, terrain becomes snow-covered (white/bluish-white)
   - **Wind Sounds**: Ambient wind whistling in high mountains (elevation >10 units)
   - Steep slopes and dramatic elevation changes
   - Landmark type: "mountain"

2. **Rocky Hills**
   - Medium elevation (5.0-8.0 units)
   - Brown-gray mixed coloring
   - Moderate slopes
   - Landmark type: "hill"

3. **Grasslands**
   - Low elevation (<5.0 units)
   - Green-brown earthy colors
   - Gentle slopes and valleys
   - May contain lakes in valley areas

### Technical Details
- Biome noise layer controls regional variation
- Seamless transitions between biomes
- Metadata tracking for each chunk's biome type
- Terrain material detection for gameplay systems

## Footstep Sound System

Dynamic footstep sounds that vary based on terrain material:

### Features
- **Procedural Sound Generation**: Uses AudioStreamGenerator for real-time synthesis
- **Material-Based Variation**:
  - **Stone**: Higher frequency (150Hz), crisp and hard sound
  - **Rock**: Medium frequency (120Hz), moderate hardness
  - **Grass**: Lower frequency (80Hz), soft and muffled
- **Movement Detection**: Sounds trigger only when moving
- **Timing**: Regular intervals based on movement speed

### Technical Details
- Exponential decay envelope for natural sound falloff
- Mix of tone and noise for realistic texture
- Lightweight procedural generation (no audio file loading)
- Integrates with terrain material detection system

## Debug Narrative UI (Android-Friendly)

A comprehensive debug overlay for narrative system inspection:

### Features
- **Toggle Button**: Bug emoji (🐛) in top-right corner
- **Debug Panel**: Semi-transparent overlay with:
  - Current player position and chunk coordinates
  - Active biome and landmark type
  - Current terrain material
  - Nearby narrative markers with distances
  - Total marker count in quest system
- **Auto-Update**: Refreshes every 0.5 seconds when visible
- **Touch-Optimized**: Large buttons and clear text for mobile devices

### Usage
1. Tap the debug button (🐛) to show/hide the panel
2. View real-time information about the narrative system
3. Check terrain properties at current position
4. Monitor nearby markers for quest development

### Technical Details
- Mouse filter settings prevent interference with gameplay
- Efficient update cycle minimizes performance impact
- Works seamlessly on Android devices
- Integrates with quest hook system for live data

## Procedural Forests and Settlements

Dynamic generation of forests and settlements that adapt to chunk-based world expansion:

### Features

1. **Forest Clusters**
   - Procedurally generated tree collections
   - 15% chance per chunk to spawn a forest center
   - Radius: 15-40 world units
   - Seamless expansion across chunk boundaries
   - Density-based tree placement (0.3-0.7 trees per unit²)
   
2. **Settlement Clusters**
   - Procedurally generated building collections
   - 5% chance per chunk to spawn a settlement center
   - Radius: 12-25 world units
   - Buildings require flatter terrain (≤15° slope)
   - Density-based building placement (0.15-0.35 buildings per unit²)

3. **Procedural Low-Poly Models**
   - **Trees**: Cone canopy + cylinder trunk (~50 vertices)
   - **Buildings**: Box walls + pyramid roof (~30 vertices)
   - No external assets required
   - Vertex colors only (no textures)
   - Mobile-optimized geometry

4. **Intelligent Placement**
   - Respects terrain walkability
   - Avoids lakes and steep slopes
   - Smooth cluster influence falloff
   - Seed-based reproducibility
   - Random rotation for variety

5. **Cluster System**
   - Global cluster registry
   - Chunks query nearby clusters
   - Influence-based object distribution
   - Natural-looking boundaries
   - Performance optimized (~10ms overhead per chunk)

### Technical Details

- **Memory**: ~50KB per chunk with objects
- **Performance**: 30+ FPS on mid-range Android devices
- **Object Count**: 5-10 objects per influenced chunk
- **Shadow Casting**: Enabled for visual depth
- **Debug Visualization**: Toggle cluster boundaries (green=forest, orange=settlement)

### Usage

```gdscript
# Clusters are automatically generated during chunk creation
# Enable debug visualization to see cluster boundaries
debug_visualization.toggle_clusters()
```

See **CLUSTER_SYSTEM.md** for complete API documentation.
## Pause Menu System

A comprehensive pause menu system for desktop and mobile:

### Features
- **Pause Toggle**: Press ESC key to pause/resume the game
- **Pause Overlay**: Semi-transparent centered menu with:
  - Resume button - Returns to game
  - Settings button - Access in-game settings
  - Quit button - Exit to desktop
- **Game Tree Pause**: Properly pauses all game logic while keeping UI responsive
- **Settings Integration**: Access camera toggle and audio settings from pause menu
- **Mobile Support**: Can also be triggered from mobile settings menu

### Desktop Controls
- Press **ESC** to open/close pause menu
- Click buttons to navigate
- ESC also resumes the game

### Mobile Access
- Tap the menu button (☰) in top-left
- Select "Pause Game" option
- Access all pause menu features on mobile

### Technical Details
- Uses `get_tree().paused = true` for proper pause implementation
- Pause menu has `PROCESS_MODE_ALWAYS` to remain interactive
- High z-index (100+) ensures it appears above all other UI
- Clean separation between pause state and settings panels

## Improved Settings Menu

Enhanced settings menu with better organization and new features:

### New Features
- **Organized Sections**: Display, Audio, and Game sections
- **Master Volume Control**: Slider to adjust game volume (0-100%)
  - Real-time volume adjustment
  - Displays current percentage
  - Uses AudioServer for proper audio mixing
- **Camera Toggle**: Switch between first-person and third-person views
- **Pause Game Button**: Mobile-friendly pause access
- **Better Styling**: Improved colors, spacing, and button designs
  - Rounded corners on all buttons
  - Distinct color schemes per section
  - Better visual hierarchy

### Usage
- Desktop: Press ESC and click Settings
- Mobile: Tap menu button (☰) in top-left

### Settings Available
1. **Display Section**
   - Toggle First Person View

2. **Audio Section**
   - Master Volume slider (0-100%)

3. **Game Section**
   - Pause Game (mobile only, desktop uses ESC)

### Technical Details
- Volume uses decibel conversion for proper audio scaling
- Settings persist during gameplay session
- All buttons use custom styled backgrounds
- Touch-friendly sizing for mobile devices

## Future Enhancements

Potential improvements for these features:

- [ ] Save/load settings preferences
- [ ] Additional audio channels (Music, SFX, Ambient)
- [ ] Graphics quality settings
- [ ] Control customization
- [ ] Fullscreen toggle
- [ ] Pre-recorded footstep sound samples for better quality
- [ ] Customizable joystick position and size
- [ ] Multiple control schemes (swipe-to-move, tap-to-move)
- [ ] More detailed UI with minimap
- [ ] Settings menu for adjusting shadow quality
- [x] Day/night cycle with dynamic shadows - **COMPLETED**
  - Full 30-minute day cycle with sunrise/sunset animations
  - 4-hour sleep lockout period after sunset
  - Dynamic lighting and celestial objects (sun, moon, stars)
  - In-game clock display
  - **Time speed control with +/- buttons** (v1.0.24+)
- [ ] Tutorial messages for first-time players
- [x] Snow-covered mountain peaks - **COMPLETED**
  - Snow appears at elevations above 12 units
  - Smooth color transitions from rock to snow
- [x] Wind whistling sounds in high mountains - **COMPLETED**
  - Ambient wind sound in mountain regions with elevation >10 units
  - Spatial 3D audio with distance attenuation
- [ ] Weather effects that affect footstep sounds
- [ ] Debug UI customization options
- [ ] Mesh instancing for forests and settlements
- [ ] LOD system for distant objects
- [ ] More tree and building variations
- [ ] Biome-specific cluster types (pine forests, tropical settlements)

## Wind and Snow in Mountain Regions

Mountain regions now feature enhanced atmospheric effects:

### Snow Coverage
- **Elevation Threshold**: Snow appears at elevations above 12 units
- **Visual Appearance**: Smooth transition from rocky gray to bluish-white snow
- **Color Blending**: Progressive snow coverage based on height (fully snow-covered at highest peaks)
- **Biome Integration**: Only applies to mountain biome regions

### Wind Whistling Sounds
- **Ambient Sound**: Procedural wind whistling in high mountain regions
- **Activation Threshold**: Mountain biome with average elevation >10 units
- **Sound Design**: 
  - Low frequency rumble (30Hz) for wind base
  - High frequency whistle (800Hz) for wind through mountain gaps
  - Natural noise texture for realism
  - Slow amplitude modulation for varying intensity
- **Spatial Audio**: 3D positioned sound with 50-unit audible range
- **Performance**: Lightweight procedural generation using AudioStreamGenerator

### Technical Details
```gdscript
# Snow coverage constants
const SNOW_START_ELEVATION = 12.0  # Height where snow begins
const SNOW_TRANSITION_RANGE = 8.0  # Gradual transition to full snow

# Wind sound configuration
const WIND_ELEVATION_THRESHOLD = 10.0  # Minimum avg height for wind
const WIND_MAX_DISTANCE = 50.0  # Audible range in units
const WIND_VOLUME_DB = -15.0  # Quieter ambient sound
```

### Usage
Wind and snow are automatically applied during chunk generation:
- No configuration needed - features activate based on terrain elevation
- Snow visible immediately on high mountain terrain
- Wind sound starts playing when chunk is generated
- Both features contribute to immersive mountain atmosphere


## Path System and Starting Location

A procedural path/road system (Wegesystem) and starting location (Startplatz) that creates an immersive starting experience:

### Path System Features
- **No path at starting point**: The starting location (chunk 0,0) has no paths, providing an unmarked starting area
- **Chunk Continuity**: Paths seamlessly extend across chunk boundaries
- **Random Branching**: 15% probability for paths to branch
- **Cluster Targeting**: Branches intelligently aim toward forests and settlements
- **Path Types**: Main paths, branches, forest paths, and village paths
- **Endpoint Detection**: Paths can terminate near clusters or randomly
- **Visual Representation**: Rendered as colored mesh overlays (dirt brown)

### Starting Location Features
- **Central Cairn**: Stacked stone marker at the world origin (0, 0, 0)
- **Standing Stones**: 6 menhirs arranged in a circle around the starting area
- **Procedural Generation**: No external model files required
- **Terrain Adaptation**: All objects automatically adjust to terrain height
- **Consistent Appearance**: Fixed seed ensures reproducible generation

### Configuration
```gdscript
# Path System Constants
BRANCH_PROBABILITY = 0.15       # 15% chance to branch
ENDPOINT_PROBABILITY = 0.05     # 5% chance to end randomly
DEFAULT_PATH_WIDTH = 1.5        # Path width in world units
PATH_ROUGHNESS = 0.3            # Path curvature (0-1)

# Starting Location Constants
LOCATION_RADIUS = 8.0           # Radius of starting area
NUM_MARKER_STONES = 6           # Number of standing stones
```

### Usage
```gdscript
# Get path segments for a chunk
var segments = PathSystem.get_path_segments_for_chunk(chunk_pos, world_seed)

# Manually create starting location
var starting_loc = StartingLocation.new()
starting_loc.adjust_to_terrain(world_manager)
```

### Future Enhancements
- Sound effects at path endpoints (placeholder implemented)
- Path decoration (stones, grass patches)
- Terrain flattening along paths
- World characteristics system (Zeit, Epoche, Stil) for varied path styles
- Path quality levels (dirt → cobblestone → paved)
- Bridge generation for water crossings

See [PATH_SYSTEM.md](PATH_SYSTEM.md) for complete documentation.

## Crystal Collection System

An interactive collectible system where crystals spawn on rocks throughout the world:

### Crystal Types
- **Mountain Crystal** (Clear/White) - Common (35% spawn chance)
- **Emerald** (Green) - Uncommon (25% spawn chance)
- **Garnet** (Dark Red) - Uncommon (20% spawn chance)
- **Amethyst** (Purple) - Uncommon (20% spawn chance)
- **Ruby** (Bright Red) - Rare (8% spawn chance)
- **Sapphire** (Deep Blue) - Rare (7% spawn chance)

### Features
- **Procedural Crystal Generation**: Hexagonal prism shapes with pointed tops
- **Size Variation**: Crystals spawn in slightly different sizes (0.8x to 1.5x)
- **Visual Effects**: Transparent materials with emission for magical glow
- **Spawn System**: 35% of rocks spawn 1-3 crystals on their surface
- **Collection Mechanics**: 
  - Desktop: Click crystals with mouse
  - Mobile: Tap crystals on screen
  - Smooth collection animation (crystal floats up and disappears)
- **Inventory Tracking**: Each crystal type counted separately
- **UI Counter**: Top-right display showing collected crystals by type with colored icons

### Technical Details
- **Collision Detection**: Area3D with sphere collision for easy mobile tapping
- **Performance**: Low-poly meshes (~50 vertices) with minimal overhead
- **Integration**: Works seamlessly with chunk-based terrain generation
- **Seed-Based**: Crystal placement is reproducible based on world seed

### Configuration
```gdscript
# In chunk.gd
const CRYSTAL_SPAWN_CHANCE = 0.35  # 35% of rocks have crystals
const CRYSTALS_PER_ROCK_MIN = 1
const CRYSTALS_PER_ROCK_MAX = 3
```

### Future Enhancements
- [ ] Crystal crafting system
- [ ] Crystal-powered abilities
- [ ] Save/load crystal inventory
- [ ] Sound effects and particle effects
- [ ] Trading system
- [ ] Achievements for rare crystal collection

See [CRYSTAL_SYSTEM.md](docs/systems/CRYSTAL_SYSTEM.md) for complete documentation.

## Ocean and Lighthouse System

A new ocean biome and coastal lighthouse system has been added to create large bodies of water spanning multiple chunks with navigational lighthouses.

### Ocean Features
- **Ocean Biome**: Large bodies of water in low-elevation areas (elevation ≤ -8.0)
- **Multi-Chunk Coverage**: Oceans span multiple adjacent chunks creating seas
- **Visual Appearance**: Deep blue semi-transparent water with sandy seabed
- **Water Mesh**: Full-chunk water plane at ocean level

### Lighthouse Features
- **Coastal Placement**: Automatically placed on chunks adjacent to ocean
- **Regular Spacing**: Lighthouses appear every ~80 world units along coastline
- **Distinctive Design**: 8-unit tall tower with red and white stripes
- **Beacon Light**: Warm yellow light with 30-unit visibility range
- **Navigation Aid**: Helps players locate coastlines and navigate around water

### Visual Details
- **Tower**: 4-section cylinder with alternating white/red stripes
- **Structure**: Platform, beacon housing, and red conical roof
- **Lighting**: OmniLight3D at top for realistic beacon effect
- **Ocean Water**: Smooth specular surface with transparency

### Technical Implementation
- **Biome Detection**: Based on average chunk elevation during metadata calculation
- **Coastal Detection**: Checks neighboring chunks for ocean presence
- **Grid Placement**: Lighthouses placed on regular grid to ensure spacing
- **Performance**: Minimal overhead with simple water meshes and sparse lighthouse placement

### Configuration
```gdscript
# In chunk.gd
const OCEAN_LEVEL = -8.0              # Elevation threshold for ocean
const LIGHTHOUSE_SPACING = 80.0        # Distance between lighthouses
```

See [OCEAN_LIGHTHOUSE_SYSTEM.md](docs/systems/OCEAN_LIGHTHOUSE_SYSTEM.md) for complete documentation.
