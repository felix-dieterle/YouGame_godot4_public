# Scripts Architecture

## Core Game Systems

### World Management
- **world_manager.gd**: Manages chunk loading/unloading based on player position
- **chunk.gd**: Individual terrain chunk with heightmap, walkability, and metadata

### Characters
- **player.gd**: Player controller with movement and camera (optional)
- **npc.gd**: NPC with simple state machine (Idle, Walk)

### Narrative System
- **narrative_marker.gd**: Markers for story events and points of interest
- **quest_hook_system.gd**: Generates quests from narrative markers

### Debugging
- **debug_visualization.gd**: Visualization tools for chunks and walkability

## Class Diagram

```
Node3D (Main Scene)
├── WorldManager (world_manager.gd)
│   └── Chunk[] (chunk.gd)
│       └── MeshInstance3D (terrain mesh)
├── Player (player.gd) [optional]
│   └── Camera3D
├── NPC[] (npc.gd)
│   └── MeshInstance3D
├── QuestHookSystem (quest_hook_system.gd)
│   └── NarrativeMarker[] (narrative_marker.gd)
└── DebugVisualization (debug_visualization.gd)
```

## Data Flow

1. **WorldManager** tracks player position
2. **WorldManager** loads/unloads **Chunks** based on view distance
3. **Chunk** generates terrain using seed-based noise
4. **Chunk** calculates walkability and metadata
5. **NPCs** query terrain height from **WorldManager**
6. **QuestHookSystem** creates quests from **NarrativeMarkers**
7. **DebugVisualization** renders debug overlays

## Key Algorithms

### Terrain Generation
1. Initialize FastNoiseLite with seed
2. Sample noise at world coordinates
3. Generate heightmap vertices
4. Calculate slopes and walkability
5. Smooth terrain if needed
6. Build mesh with vertex colors

### Chunk Loading
1. Calculate current player chunk position
2. Determine chunks within view distance
3. Load missing chunks
4. Unload distant chunks
5. Maintain active chunks dictionary

### Walkability Check
1. For each cell, get corner heights
2. Calculate maximum height difference
3. Convert to slope angle (degrees)
4. Mark as walkable if slope ≤ 30°
5. Count walkable cells
6. Smooth terrain if < 80% walkable

## Extension Points

- Add biome-specific terrain generation in `chunk.gd`
- Implement advanced NPC AI in `npc.gd`
- Add story generation in `quest_hook_system.gd`
- Create LOD system in `chunk.gd`
- Add multiplayer support in `world_manager.gd`
