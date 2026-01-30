# Quest/Narrative Systems

Dynamic quest generation and narrative marker systems.

## Files

### Quest Hook System (`quest_hook_system.gd`)
- Dynamic quest generation
- Quest management and tracking
- Narrative event coordination

### Narrative Marker (`narrative_marker.gd`)
- Points of interest in the world
- Quest location markers
- Interactable narrative elements

### Narrative Demo (`narrative_demo.gd`)
- Demonstration of narrative system
- Testing and example implementation
- May be used for tutorial/introduction

## Usage

```gdscript
# Quest system
const QuestHookSystem = preload("res://scripts/systems/quest/quest_hook_system.gd")
var quest_system = QuestHookSystem.new()
add_child(quest_system)

# Narrative markers are placed by chunks
const NarrativeMarker = preload("res://scripts/systems/quest/narrative_marker.gd")
var marker = NarrativeMarker.new()
marker.position = location
add_child(marker)
```

## Integration

- Narrative markers are generated during chunk creation
- Quest system coordinates with world manager
- Markers serve as quest objectives and points of interest
