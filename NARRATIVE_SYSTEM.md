# Narrative Marker and Quest Hook System

This document describes the narrative marker and quest hook system implementation for YouGame.

## Overview

The narrative marker system generates dynamic quest markers based on procedural terrain without fixed story text. Instead, markers contain flexible metadata that can be used to generate context-aware quests and narrative elements.

## Key Features

### 1. Dynamic Marker Generation

Markers are automatically generated during chunk generation based on terrain metadata:

- **Landmark chunks** (hills, valleys) generate up to 2 markers
- **Open terrain** (openness > 0.7) generates 1 marker
- **Regular chunks** have a 30% chance of generating 1 marker

### 2. Flexible Metadata Instead of Fixed Story

Each marker contains metadata instead of hardcoded narrative:

```gdscript
marker.metadata = {
    "biome": "grassland",
    "landmark_type": "hill",
    "openness": 0.8,
    "chunk_seed": 12345
}
```

This allows for:
- Dynamic story generation based on context
- Localization without changing marker data
- Procedural quest narratives
- Reusable markers for different quest types

### 3. Quest Hook System

The `QuestHookSystem` selects and manages markers for quests:

- **Marker registration**: Automatically happens when chunks load
- **Marker selection**: Chooses markers based on importance and proximity
- **Quest creation**: Generates quests from selected markers
- **Demo mode**: Showcases the system with dummy story elements

## Architecture

### NarrativeMarker Class

Located in `scripts/narrative_marker.gd`

**Properties:**
- `marker_id`: Unique identifier
- `chunk_position`: Chunk coordinates (Vector2i)
- `world_position`: 3D position (Vector3)
- `marker_type`: Type of marker ("discovery", "encounter", "landmark")
- `importance`: Priority value (0.0 to 1.0)
- `is_activated`: Whether marker has been used
- `metadata`: Dictionary of flexible contextual data

### Chunk Integration

Located in `scripts/chunk.gd`

**New Methods:**
- `_generate_narrative_markers()`: Creates markers based on chunk metadata
- `_create_marker_for_chunk()`: Creates individual marker with metadata
- `get_narrative_markers()`: Returns array of markers for this chunk

**Marker Generation Logic:**
```gdscript
# Landmark chunks get 2 markers with high importance
if landmark_type == "hill":
    marker_type = "landmark"
    importance = 0.8

# Open areas get encounter markers
elif openness > 0.7:
    marker_type = "encounter"
    importance = 0.6

# Regular areas get discovery markers
else:
    marker_type = "discovery"
    importance = 0.5
```

### QuestHookSystem Class

Located in `scripts/quest_hook_system.gd`

**Key Features:**
- Manages available markers
- Tracks active quests
- Selects best markers for quests
- Demo mode for story generation

**Demo Mode Functions:**
- `enable_demo_mode()`: Activates demo mode
- `generate_dummy_story_for_marker()`: Creates contextual story from metadata
- `create_demo_quest()`: Generates example quest with 1-3 objectives
- `print_marker_summary()`: Displays all available markers

### WorldManager Integration

Located in `scripts/world_manager.gd`

**Integration:**
```gdscript
func _load_chunk(chunk_pos: Vector2i):
    var chunk = Chunk.new(chunk_pos.x, chunk_pos.y, WORLD_SEED)
    chunk.generate()
    
    # Auto-register markers
    if quest_hook_system:
        var markers = chunk.get_narrative_markers()
        for marker in markers:
            quest_hook_system.register_marker(marker)
```

## Usage

### Basic Usage

The system works automatically:

1. **Chunks generate** → Markers are created based on metadata
2. **Markers register** → WorldManager registers them with QuestHookSystem
3. **Quests created** → QuestHookSystem selects appropriate markers

### Demo Mode

To enable demo mode and see the system in action:

```gdscript
# In your code
var quest_system = get_node("QuestHookSystem")
quest_system.enable_demo_mode()

# Print available markers
quest_system.print_marker_summary()

# Create a demo quest
var quest = quest_system.create_demo_quest()
```

### Using the Demo Scene

Run `scenes/demo_narrative.tscn` to see the full demo:

1. Scene loads with terrain generation
2. NarrativeDemo script activates after 2 seconds
3. Prints marker summary to console
4. Creates demo quest with generated story
5. Tracks player progress toward objectives

### Custom Quest Creation

Create quests programmatically:

```gdscript
# Get nearby markers
var nearby = quest_system.get_nearby_markers(player_position, 100.0)

# Select best marker
var marker = quest_system.select_quest_marker(player_position, 100.0)

# Create quest from marker
var quest = quest_system.create_quest_from_marker(marker)

# In demo mode, generate story
if quest_system.demo_mode:
    var story = quest_system.generate_dummy_story_for_marker(marker)
    print("Quest objective: " + story)
```

## Performance Considerations

The system is optimized for mobile performance:

### Lightweight Marker Generation
- **Limited markers per chunk**: Maximum 2 markers per chunk
- **Efficient selection**: Only generates markers for walkable positions
- **Fast metadata lookup**: Uses dictionaries for O(1) access
- **No expensive operations**: All generation happens during chunk loading

### Memory Efficient
- **Small marker footprint**: ~200 bytes per marker
- **Metadata-only storage**: No large strings or assets
- **Marker cleanup**: Markers are removed when chunks unload

### Typical Overhead
- **Per chunk**: 0-2 markers × ~200 bytes = 0-400 bytes
- **View distance 3**: ~49 chunks × 1 marker average = ~10 KB
- **Impact**: Negligible (<1% of chunk memory)

## Example Output

When running the demo, you'll see output like:

```
========================================
NARRATIVE MARKER DEMO MODE ACTIVATED
========================================

QuestHookSystem: 12 markers available
  - marker_0_0_0 (type: discovery, importance: 0.50) at (15.3, 2.1, 18.7)
  - marker_1_1_0 (type: landmark, importance: 0.80) at (45.2, 8.3, 52.1)
  - marker_0_1_0 (type: encounter, importance: 0.60) at (12.8, 3.5, 48.9)
  ...

--- Creating new demo quest ---
QuestHookSystem: Created demo quest 'Demo Quest: Journey Through the Land' with 3 objectives
  Objective 1: Explore the unknown area in the grassland near the elevated hill (rough terrain) at (45.2, 8.3, 52.1)
  Objective 2: Meet someone at this location in the grassland (open terrain) at (12.8, 3.5, 48.9)
  Objective 3: Investigate the mysterious location in the grassland (rough terrain) at (15.3, 2.1, 18.7)

Quest created successfully!
Quest ID: demo_quest_123456789
Title: Demo Quest: Journey Through the Land
Number of objectives: 3
```

## Testing

Run the narrative marker tests:

```bash
# If Godot is available
./run_tests.sh

# Or manually
godot --headless --path . res://tests/test_scene.tscn
```

Tests include:
- Marker generation validation
- Metadata structure verification
- Quest system registration
- Demo quest creation
- Marker selection logic

## Future Enhancements

Potential improvements:

1. **Story Templates**: More diverse story generation templates
2. **Quest Chains**: Link multiple quests together
3. **Difficulty Scaling**: Adjust quest complexity based on player progress
4. **Rewards System**: Define rewards in marker metadata
5. **NPC Integration**: Assign NPCs to markers for dialogue
6. **Localization**: Multi-language story generation
7. **Quest Types**: More varied quest objectives (collect, defend, etc.)
8. **Visual Markers**: 3D markers in world to highlight quest locations

## Files

- `scripts/narrative_marker.gd` - Marker data structure
- `scripts/quest_hook_system.gd` - Quest management and selection
- `scripts/chunk.gd` - Marker generation integration
- `scripts/world_manager.gd` - Automatic marker registration
- `scripts/narrative_demo.gd` - Demo mode implementation
- `scenes/demo_narrative.tscn` - Demo scene
- `tests/test_narrative_markers.gd` - Unit tests
- `tests/test_narrative_system.gd` - Integration tests
- `NARRATIVE_SYSTEM.md` - This documentation

## License

Same as the main project.
