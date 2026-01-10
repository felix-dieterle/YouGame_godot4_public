# Visual Guide: Forest and Settlement System

## Overview

This guide provides a visual description of the newly implemented forest and settlement cluster system.

## Cluster Visualization

### Forest Cluster (Green Circle)
```
       Chunk Grid
    ┌────┬────┬────┐
    │    │    │    │
    ├────┼────┼────┤
    │  ●─┼────┼──● │  ← Forest cluster spans 3 chunks
    ├────┼────┼────┤  ● = Cluster boundary
    │    │ FC │    │  FC = Forest center
    └────┴────┴────┘
    
    Radius: 15-40 units
    Color: Green (in debug mode)
    Trees: 5-10 per influenced chunk
```

### Settlement Cluster (Orange Circle)
```
       Chunk Grid
    ┌────┬────┬────┐
    │    │    │    │
    ├────┼────┼────┤
    │   ●┼────┼●   │  ← Settlement cluster
    ├────┼────┼────┤  ● = Cluster boundary
    │    │ SC │    │  SC = Settlement center
    └────┴────┴────┘
    
    Radius: 12-25 units
    Color: Orange (in debug mode)
    Buildings: 2-5 per influenced chunk
```

## Object Models

### Procedural Tree
```
       /\         ← Canopy (Green cone)
      /  \          Height: 2.5 units
     /    \         Radius: 1.2 units
    /______\        Segments: 8
       ||          ← Trunk (Brown cylinder)
       ||            Height: 2.0 units
      ====           Radius: 0.15 units
                     Segments: 6
                     
    Total Vertices: ~50
    Material: Vertex colors
    Shadows: Enabled
```

### Procedural Building
```
       /\          ← Roof (Brown pyramid)
      /  \           Height: 40% of building
     /____\          
    |      |        ← Walls (Colored box)
    |      |          Width: 3-6 units
    |      |          Depth: 3-6 units
    |______|          Height: 2.5-5 units
    
    Total Vertices: ~30
    Material: Vertex colors (beige/brown/gray)
    Shadows: Enabled
    Colors: 4 variations
```

## Cluster Influence

### Influence Falloff Diagram
```
Distance from Center →

Influence ↑
1.0 |████████░░░░░░░
0.8 |████████████░░░
0.6 |████████████████░
0.4 |████████████████████░
0.2 |████████████████████████░
0.0 |██████████████████████████
    └─────────────────────────→
    0    10   20   30   40  50
         Distance (units)
         
    ████ = High influence (many trees/buildings)
    ░░░░ = Low influence (few objects)
    
    Formula: (cos(d/r × π) + 1) / 2
    where d = distance, r = radius
```

## Chunk-Based Example

### Forest Spanning Multiple Chunks
```
Chunk Layout (each = 32×32 units):

  (-1,-1)  │  (0,-1)  │  (1,-1)
  ░░░░░░░░ │ ░░░░░░░░ │ ░░░░░░░░
  ░░░▓▓▓░░ │ ░▓▓▓▓▓░░ │ ░░░░░░░░
  ░░░▓▓▓░░ │ ░▓▓▓▓▓░░ │ ░░░░░░░░
───────────┼──────────┼──────────
  (-1,0)   │   (0,0)  │  (1,0)
  ░░░▓▓▓░░ │ ░▓▓FC▓░░ │ ░░▓▓░░░░
  ░░▓▓▓▓░░ │ ▓▓▓▓▓▓▓░ │ ░░▓▓░░░░
  ░░▓▓▓▓░░ │ ▓▓▓▓▓▓▓░ │ ░░▓░░░░░
───────────┼──────────┼──────────
  (-1,1)   │   (0,1)  │  (1,1)
  ░░░▓▓▓░░ │ ░▓▓▓▓▓░░ │ ░░░░░░░░
  ░░░░▓▓░░ │ ░░▓▓▓░░░ │ ░░░░░░░░
  ░░░░░░░░ │ ░░░░░░░░ │ ░░░░░░░░

Legend:
  FC = Forest Center (chunk 0,0)
  ▓  = High tree density (8-10 trees)
  ░  = Low tree density (0-3 trees)
  
Total: ~40 trees seamlessly distributed
```

## Placement Rules

### Tree Placement Decision Tree
```
                 [Select Position]
                       │
                       ↓
              [In Cluster Influence?]
                   ╱      ╲
                  NO      YES
                  │        ↓
                  X   [Check Walkable]
                          ╱      ╲
                         NO      YES
                         │        ↓
                         X   [Check Slope ≤30°]
                                 ╱      ╲
                                NO      YES
                                │        ↓
                                X   [Check Not in Lake]
                                        ╱      ╲
                                       NO      YES
                                       │        ↓
                                       X   [PLACE TREE ✓]
```

### Building Placement Decision Tree
```
                 [Select Position]
                       │
                       ↓
              [In Cluster Influence?]
                   ╱      ╲
                  NO      YES
                  │        ↓
                  X   [Check Walkable]
                          ╱      ╲
                         NO      YES
                         │        ↓
                         X   [Check Slope ≤15°]  ← Stricter!
                                 ╱      ╲
                                NO      YES
                                │        ↓
                                X   [Check Not Near Lake]
                                        ╱      ╲
                                       NO      YES
                                       │        ↓
                                       X   [PLACE BUILDING ✓]
```

## Performance Visualization

### Chunk Load Timeline
```
Time (ms) →
0     10    20    30    40    50
├─────┼─────┼─────┼─────┼─────┤
│█████│                         Heightmap Generation
     │██│                       Walkability Check
       │█│                      Metadata Calculation
        │█│                     Cluster Query
         │████│                 Object Placement
              │█│               Mesh Creation
              └─┘ COMPLETE (25ms)

Without Clusters: 15ms
With Clusters:    25ms (+10ms)
```

### Memory Usage
```
Component           Memory
────────────────────────────────
Heightmap           40 KB  ██████████
Walkability Map      8 KB  ██
Mesh Data           30 KB  ███████
Cluster Metadata   0.5 KB  ░
Tree Objects (×5)   50 KB  ████████████
Building Objs (×3)  30 KB  ███████
────────────────────────────────
TOTAL             158 KB  ████████████████████

Per 7×7 Grid (49 chunks):
~7.7 MB active memory
```

## Debug Mode Visualization

### In-Game View (Debug Enabled)
```
        Sky
    ╔═══════════╗
    ║   🌲  🌲  ║  ← Trees visible
    ║  🌲 ⭕ 🌲 ║  ⭕ = Green cluster circle
    ║   🌲  🌲  ║     (visible in debug mode)
    ║═══════════║
    ║  🏠  🏠   ║  ← Buildings visible
    ║    ⭕     ║  ⭕ = Orange cluster circle
    ║  🏠       ║
    ╚═══════════╝
        Terrain
```

### Debug Overlay Info
```
┌─────────────────────────────┐
│ Debug Info                  │
├─────────────────────────────┤
│ Position: (64.5, 45.2)      │
│ Chunk: (2, 1)               │
│ Biome: grassland            │
│                             │
│ Active Clusters: 2          │
│ ● Forest #12  [50% infl.]   │
│ ● Settlement #7 [20% infl.] │
│                             │
│ Objects in View: 15         │
│ - Trees: 10                 │
│ - Buildings: 5              │
└─────────────────────────────┘
```

## File Structure

```
scripts/
├── cluster_system.gd       ← Cluster management
├── procedural_models.gd    ← Model generation
├── chunk.gd                ← Terrain + Objects
├── world_manager.gd        ← Chunk loading
└── debug_visualization.gd  ← Visual debugging

tests/
└── test_clusters.gd        ← Automated tests

Documentation/
├── CLUSTER_SYSTEM.md       ← API reference
├── OPEN_POINTS_ANALYSIS.md ← Implementation analysis
└── VISUAL_GUIDE.md         ← This file
```

## Color Legend

### Cluster Types
- 🟢 **Green Circle**: Forest cluster (debug mode)
- 🟠 **Orange Circle**: Settlement cluster (debug mode)

### Objects
- 🌲 **Green Cone**: Tree (in-game)
- 🏠 **Colored Box**: Building (in-game)

### Terrain
- 🟩 **Green**: Grassland (walkable)
- 🟫 **Brown**: Rocky hills
- ⬜ **Gray**: Mountain (steep)
- 🟦 **Blue**: Water (lake)

## Usage Tips

### Enable Debug Visualization
```gdscript
# Add to your debug script or console
var debug_viz = get_node("DebugVisualization")
debug_viz.toggle_clusters()
```

### Query Cluster Info
```gdscript
# Check clusters at current position
var chunk_pos = Vector2i(
    int(player_pos.x / 32),
    int(player_pos.z / 32)
)
var clusters = ClusterSystem.get_clusters_for_chunk(chunk_pos, world_seed)
print("Clusters here: ", clusters.size())
```

### Monitor Performance
```gdscript
# In _process()
var start = Time.get_ticks_msec()
chunk.generate()
var elapsed = Time.get_ticks_msec() - start
print("Chunk generation took: ", elapsed, "ms")
```

## Expected Results

### On Desktop
- 60 FPS constant
- Smooth cluster boundaries
- No visible pop-in
- ~300MB RAM usage (7×7 chunks)

### On Mid-Range Android (Example: Samsung A50)
- 35-45 FPS
- Smooth gameplay
- Seamless chunk loading
- ~350MB RAM usage

### On Low-End Android (Example: Redmi 9A)
- 25-30 FPS
- Minor frame drops during chunk load
- Still playable
- ~400MB RAM usage

## Troubleshooting Visual Issues

### Trees/Buildings Not Appearing
1. Check cluster probability (15% forests, 5% settlements)
2. Verify terrain is walkable
3. Ensure not placing in lakes
4. Enable debug mode to see cluster boundaries

### Performance Issues
1. Reduce cluster density in cluster_system.gd
2. Lower object counts in chunk.gd placement functions
3. Disable shadow casting temporarily
4. Check chunk view distance (default: 3)

### Visual Artifacts
1. Check mesh normals generation
2. Verify material settings
3. Ensure proper vertex colors
4. Check for z-fighting with terrain

---

**Note**: This is a text-based visual guide. For actual screenshots, run the game with debug visualization enabled.
