# Minimap Visual Comparison

## Before (Fog of War)

```
┌─────────────────────────────┐
│  Minimap (Top-Right)        │
│                             │
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │  ← Completely black (unexplored)
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │
│  ▓▓▓▓▓▓▓▓███████▓▓▓▓▓▓▓▓  │  
│  ▓▓▓▓▓▓▓████☀████▓▓▓▓▓▓▓  │  ← Visited areas (bright)
│  ▓▓▓▓▓▓▓███████▓▓▓▓▓▓▓▓  │     (Player at center ☀)
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │
│                             │
│  ⬆ N                        │  ← Compass
└─────────────────────────────┘

Legend:
▓ = Black (unexplored, invisible)
█ = Bright colors (visited areas)
☀ = Player position
```

## After (Dimmed Preview)

```
┌─────────────────────────────┐
│  Minimap (Top-Right)        │
│                             │
│  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  │  ← Dimmed (65% darker, visible)
│  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  │
│  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  │
│  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  │
│  ▒▒▒▒▒▒▒▒███████▒▒▒▒▒▒▒▒  │  
│  ▒▒▒▒▒▒▒████☀████▒▒▒▒▒▒▒  │  ← Visited areas (bright)
│  ▒▒▒▒▒▒▒███████▒▒▒▒▒▒▒▒  │     (Player at center ☀)
│  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  │
│  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  │
│  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  │
│  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  │
│                             │
│  ⬆ N                        │  ← Compass
└─────────────────────────────┘

Legend:
▒ = Dimmed colors (unexplored, slightly visible)
█ = Bright colors (visited areas)
☀ = Player position
```

## Color Examples

### Water (Deep)
- **Unexplored**: RGB(0.07, 0.14, 0.28) - Dark blue, barely visible
- **Visited**: RGB(0.23, 0.46, 0.92) - Bright blue, clearly visible

### Plains/Grass  
- **Unexplored**: RGB(0.105, 0.21, 0.105) - Very dark green
- **Visited**: RGB(0.345, 0.69, 0.345) - Bright green

### Mountains
- **Unexplored**: RGB(0.175, 0.14, 0.105) - Dark brown/gray
- **Visited**: RGB(0.575, 0.46, 0.345) - Light brown/gray

## Key Differences

| Aspect | Before (Fog of War) | After (Dimmed Preview) |
|--------|-------------------|----------------------|
| Unexplored areas | Completely black | Dimmed (65% darker) |
| Strategic overview | Limited to visited areas | Entire map visible |
| Exploration feedback | Binary (seen/unseen) | Gradual (dim/bright) |
| Performance | Lower (fewer queries) | Higher (all terrain) |
| User experience | Need to explore first | Can plan ahead |

## Implementation Details

```gdscript
# In _render_map() function:

# Get terrain color
var color = _get_terrain_color(world_pos)

# Apply brightness based on visited status
if chunk_pos in visited_chunks:
    # Visited: 15% brighter
    color = color.lightened(0.15)
else:
    # Unexplored: 65% darker (controlled by UNEXPLORED_DARKNESS)
    color = color.darkened(UNEXPLORED_DARKNESS)
```

## Adjustable Parameter

The visibility of unexplored areas can be adjusted by changing one constant:

```gdscript
const UNEXPLORED_DARKNESS: float = 0.65  # Current value

# For more visible unexplored areas:
const UNEXPLORED_DARKNESS: float = 0.5  # Less dark

# For less visible unexplored areas (better performance):
const UNEXPLORED_DARKNESS: float = 0.8  # More dark

# To go back to fog of war:
const UNEXPLORED_DARKNESS: float = 0.95  # Nearly black
```

## Performance Impact

The change increases terrain queries from ~50% to 100% of the visible minimap area. However, existing optimizations mitigate this:

1. **Pixel Sampling**: Only every 2nd pixel is queried (75% reduction)
2. **Update Rate**: 5 FPS instead of 10 FPS (50% reduction)
3. **Map Size**: 15% of screen instead of 20% (44% fewer pixels)
4. **Movement Threshold**: Only updates on significant movement

**Net result**: Should have acceptable performance impact while providing better strategic overview.
