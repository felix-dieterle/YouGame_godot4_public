# Unique Mountain Chunk - Visual Guide

## Mountain Structure

```
                             /\        <- Summit (~40-50 units high)
                            /  \
                           /    \
                    Cave  |      |  Cave  <- Cave 5 (highest)
                         /        \
                        /    /\    \
                Cave   |    /  \    |  Cave  <- Caves 3-4 (mid-high)
                      /    /    \    \
                     /    |      |    \
              Cave  |     |      |     |  <- Cave 1-2 (mid-level)
                   /      |      |      \
          Path ~~/        |      |       \~~
             ~~/          |      |          \~~
           ~~/            |      |             \~~  <- Winding paths
         ~~/              |______|                \~~
       ~~/           Mountain Base                   \~~
     ~~/            (~20 units high)                    \~~
   ~~/______________________________________________ Chunk Base ___\~~
   
   [Chunk boundary: 32x32 units]
```

## Cave Chamber Structure

```
Side View of a Cave:
                 Mountain
                 Surface
                    |
                    |
        ============|============  <- Entrance (opening)
       /            |            \
      /             |             \
     |              |              |  <- Cave walls (inverted sphere)
     |              |              |
     |              V              |
     |         Player enters       |
     |                             |
      \                           /
       \          /\             /
        \________/  \__________/   <- Flat walkable floor
        
Top View of Cave:
        
           Mountain
             Wall
        _____|_____
       /           \
      /             \    
     |    _____      |
     |   |     |     |  <- Entrance opening
     |   |     |_____|     (faces outward)
     |              
     |    Chamber   |
     |   Interior   |
      \            /
       \__________/
       
       [Radius: 3-6 units]
```

## Path System

```
Plan View (top-down):

   Chunk Center
        *
        |
        |  Start
        *--------
                 \~~~
                   \~~  Segment 1
                     \~
                      *  <- Curve point 1
                       \~~~
                         \~~  Segment 2  
                           \~
                            *  <- Curve point 2
                             \~~~
                               \~~  Segment 3
                                 \~
                                  *  <- Cave entrance
                                 | |
                              [Cave]
                              
   Path Width: 1.5 units (mountain trail)
   Deviation: ±3 units (sine wave)
```

## Generation Algorithm Flow

```
┌─────────────────────────────────────────────────┐
│ 1. Hash Chunk Position                          │
│    hash(chunk_x, chunk_z) % 73 == 42?           │
└─────────────┬───────────────────────────────────┘
              │
              ├─ No  ──> Normal chunk generation
              │
              └─ Yes ──> UNIQUE MOUNTAIN CHUNK
                         │
         ┌───────────────┴───────────────┐
         ▼                               ▼
    ┌─────────────────┐          ┌──────────────┐
    │ 2. Height Gen   │          │ 3. Cave Gen  │
    │ Multiplier: 40  │          │ Count: 3-5   │
    │ Offset: 20      │          │ Radius: 3-6  │
    └────────┬────────┘          └──────┬───────┘
             │                          │
             ▼                          ▼
    ┌─────────────────┐          ┌──────────────┐
    │ Very tall       │          │ Position     │
    │ terrain         │          │ caves at     │
    │ (~40-50 high)   │          │ elevations   │
    └────────┬────────┘          └──────┬───────┘
             │                          │
             └──────────┬───────────────┘
                        ▼
                ┌───────────────┐
                │ 4. Path Gen   │
                │ Winding paths │
                │ to each cave  │
                └───────┬───────┘
                        ▼
                ┌───────────────┐
                │ 5. Narrative  │
                │ Markers for   │
                │ quest system  │
                └───────────────┘
```

## Hash-Based Uniqueness

```
All Chunks in World:
┌────┬────┬────┬────┬────┬────┬────┐
│ 0  │ 1  │ 2  │ 3  │ 4  │ 5  │ 6  │
├────┼────┼────┼────┼────┼────┼────┤
│ 7  │ 8  │ 9  │ 10 │ 11 │ 12 │ 13 │
├────┼────┼────┼────┼────┼────┼────┤
│ 14 │ 15 │ 16 │ 17 │ 18 │ 19 │ 20 │
├────┼────┼────┼────┼────┼────┼────┤
│ 21 │ 22 │ 23 │ 24 │ 25 │ 26 │ 27 │
├────┼────┼────┼────┼────┼────┼────┤
│... │... │... │... │ 42 │... │... │  <- Only this one!
└────┴────┴────┴────┴────┴────┴────┘
                      ▲
              hash(x,z) % 73 = 42
              
Only ONE chunk in the entire world matches this condition.
Different world seeds produce different mountain locations.
```

## Cave Mesh Technical Details

```
Sphere Triangulation (simplified):

Ring 0 (top)     *----*----*
                / \  / \  /
Ring 1        *----*----*----*
             / \  / \  / \  /
Ring 2      *----*----*----*----*
              \  / \  / \  /
Ring 3         *----*----*

Each quad = 2 triangles
Normals point INWARD (inverted sphere)
Entrance opening: skip quads where normal.dot(entrance_dir) > 0.3

Floor: Flat disc at bottom
  - Separate triangle fan
  - Normal: UP
  - Y-position: -radius * 0.8
```

## Coordinate Systems

```
World Coordinates:
   Z
   ▲
   │
   └─────> X

Chunk Coordinates (integer grid):
   chunk_z
   ▲
   │
   └─────> chunk_x

Local Coordinates (within chunk):
   0 to 32 (CHUNK_SIZE)
   
World Position = chunk_coord * CHUNK_SIZE + local_coord

Example:
  Chunk (3, 5), Local (10, 15)
  World = (3*32 + 10, 5*32 + 15) = (106, 175)
```

## Performance Considerations

```
Cave Mesh Complexity:
┌──────────────────────────────────┐
│ Segments: 12                     │
│ Rings: 8                         │
│ Quads per cave: 12 × 8 = 96     │
│ Triangles per quad: 2           │
│ Triangles per cave: ~192        │
│                                  │
│ Total caves: 3-5                 │
│ Total triangles: 576-960         │
│                                  │
│ Floor triangles: 8 per cave     │
│ Total floor: 24-40              │
│                                  │
│ Grand Total: 600-1000 tris      │
└──────────────────────────────────┘

Impact: MINIMAL - well within mobile budget
Standard terrain chunk: ~4000 triangles
```

## Integration with Existing Systems

```
┌─────────────────────────────────────┐
│ WorldManager                        │
│  └─ Manages chunk loading/unload    │
│     └─ Calls chunk.generate()       │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│ Chunk (this implementation)         │
│  ├─ _detect_unique_mountain()       │
│  ├─ _generate_heightmap() [CUSTOM]  │
│  ├─ _generate_caves() [NEW]         │
│  └─ _add_mountain_paths() [NEW]     │
└─────────────┬───────────────────────┘
              │
        ┌─────┴─────┬──────────┐
        ▼           ▼          ▼
   ┌────────┐  ┌────────┐  ┌──────────┐
   │ Path   │  │ Cluster│  │ Narrative│
   │ System │  │ System │  │ Markers  │
   │ (reuse)│  │ (reuse)│  │ (reuse)  │
   └────────┘  └────────┘  └──────────┘
```

## Finding the Mountain in Game

```
Debug Steps:
1. Note world seed (default: 12345)
2. Enable debug visualization if available
3. Calculate which chunk has the mountain:
   
   for chunk_x in range(-10, 10):
       for chunk_z in range(-10, 10):
           h = hash(Vector2i(chunk_x, chunk_z))
           if (h % 73) == 42:
               print("Mountain at chunk: ", chunk_x, chunk_z)
               
4. Navigate to that chunk location:
   World X = chunk_x * 32
   World Z = chunk_z * 32
   
5. Look for VERY TALL terrain with cave openings
```

---

This visual guide supplements the technical documentation and helps understand the spatial relationships and generation logic of the unique mountain chunk feature.
