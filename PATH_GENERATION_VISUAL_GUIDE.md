# Path Generation - Visual Explanation

## Before Fix (BROKEN)

```
Chunk Grid:
┌─────┬─────┬─────┐
│     │     │     │  Chunk (-1,1)  Chunk (0,1)  Chunk (1,1)
│  ✗  │  ✗  │  ✗  │  No paths     No paths     No paths
└─────┼─────┼─────┤
│     │     │     │  Chunk (-1,0)  Chunk (0,0)  Chunk (1,0)
│  ✗  │  ⊗  │  ✗  │  No paths     NO PATHS     No paths
└─────┼─────┼─────┤                (by design)
│     │     │     │  Chunk (-1,-1) Chunk (0,-1) Chunk (1,-1)
│  ✗  │  ✗  │  ✗  │  No paths     No paths     No paths
└─────┴─────┴─────┘

⊗ = Starting chunk (no paths by design)
✗ = No paths (waiting for neighbor paths that never come)
```

**Problem**: Chunk (0,0) has no paths by design. All other chunks wait for neighbor paths. Nothing ever starts!

---

## After Fix (WORKING)

```
Chunk Grid:
┌─────┬─────┬─────┐
│     │  ═══│     │  Chunk (-1,1)  Chunk (0,1)  Chunk (1,1)
│  ✗  │══╗  │  ✗  │  No paths     SEED PATH    No paths
└─────┼──║──┼─────┤               ║
│═════│  ║  │═════│  Chunk (-1,0)  ║           Chunk (1,0)
│═══╗ │  ⊗  │╔═══│  SEED PATH    ║ (0,0)      SEED PATH
└───║─┼──║──┼─║───┤               ║  NO PATHS
│   ║ │══╝  │ ║   │  Chunk (-1,-1) Chunk (0,-1) Chunk (1,-1)
│  ✗ ║══════║ ✗   │  No paths     SEED PATH    No paths
└────║──────║─────┘

⊗ = Starting chunk (no paths by design)
═ = SEED PATHS (newly created in adjacent chunks)
║ = Path direction away from origin
✗ = No paths (too far from seed)
```

**Solution**: Adjacent chunks (distance=1 from origin) create seed paths pointing away from (0,0). These propagate outward!

---

## How Seeds Propagate

```
Step 1: Generate chunk (1,0)
  - Check neighbors: (0,0) has no paths
  - Distance from origin = 1
  - CREATE SEED PATH pointing RIGHT (away from origin)
  - Path: start=(16,16), end≈(30,20)

Step 2: Generate chunk (2,0)  
  - Check neighbors: (1,0) has a path!
  - Path exits at x≈30 (near right edge)
  - CONTINUE PATH into this chunk
  - New path: start=(0,20), end≈(15,22)

Step 3: Generate chunk (3,0)
  - Check neighbors: (2,0) has a path!
  - Path exits at x≈15 (middle, no continuation)
  - OR path reaches endpoint
  - Path system continues naturally...
```

---

## Key Insight

**The Fix**: 
```gdscript
if new_segments.is_empty():
    var distance_from_origin = abs(chunk_pos.x) + abs(chunk_pos.y)
    
    if distance_from_origin == 1:
        # CREATE SEED PATH
        var direction = Vector2(chunk_pos).normalized()  // Points away from origin
        var initial_segment = _create_segment(...)
        new_segments.append(initial_segment)
```

**Result**: 
- Chunk (0,0) stays path-free ✓
- Adjacent chunks create seeds ✓  
- Seeds propagate through existing continuation logic ✓
- Full path network emerges ✓

---

## Manhattan Distance Calculation

```
Distance from origin = |x| + |y|

Examples:
  (0,0)   -> |0| + |0| = 0  (origin, no seed)
  (1,0)   -> |1| + |0| = 1  (adjacent, CREATE SEED)
  (0,-1)  -> |0| + |-1| = 1 (adjacent, CREATE SEED)
  (1,1)   -> |1| + |1| = 2  (diagonal, no seed)
  (2,0)   -> |2| + |0| = 2  (distant, rely on continuation)
```

Only the 4 orthogonally adjacent chunks get seeds:
- (1, 0) - Right
- (-1, 0) - Left  
- (0, 1) - Down
- (0, -1) - Up

Diagonal chunks like (1,1) have distance=2, so they rely on path continuation from the adjacent chunks.

---

**Status**: ✅ Fixed  
**Visual**: ASCII diagrams showing before/after and propagation
