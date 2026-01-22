# Direction Arrows - Visual Guide

## Overview Diagram

```
                    Screen Layout
    ┌───────────────────────────────────────┐
    │                                       │
    │              [Gray Arrow]             │
    │                   ↑                   │
    │                 "Berg"                │
    │                 500m                  │
    │                                       │
    │                                       │
    │  [Blue Arrow]         [Purple Arrow]  │
    │      ←                     →          │
    │   "Wasser"              "Kristall"    │
    │    142m                   89m         │
    │                                       │
    │                                       │
    │            [Player View]              │
    │         (screen center)               │
    │                                       │
    │                                       │
    └───────────────────────────────────────┘
```

## Arrow Appearance

### Blue Water Arrow
```
     ╱╲
    ╱  ╲      ← Triangle pointing toward water
   ╱    ╲
  ╱──────╲
  
  Color: rgb(51, 128, 255)  [Light Blue]
  Label: "Wasser"
  Distance: e.g., "142m"
```

### Purple Crystal Arrow
```
     ╱╲
    ╱  ╲      ← Triangle pointing toward crystal
   ╱    ╲
  ╱──────╲
  
  Color: rgb(204, 51, 204)  [Purple/Pink]
  Label: "Kristall"
  Distance: e.g., "89m"
```

### Gray Mountain Arrow
```
     ╱╲
    ╱  ╲      ← Triangle pointing toward mountain
   ╱    ╲
  ╱──────╲
  
  Color: rgb(153, 153, 153)  [Gray]
  Label: "Berg"
  Distance: e.g., "500m"
```

## Arrow Positioning

```
         Circular Arrangement (150px radius from center)
         
              ↑ North
              │
              │  Arrows positioned based on
              │  actual direction to target
       ←──────┼──────→
              │
              │
              ↓ South
              
    Note: Arrows appear anywhere on this circle
    depending on where the target is located
    relative to the player
```

## Visibility Behavior

### Arrow States

1. **Target Far Away (> 10m)**
   ```
   Arrow: VISIBLE ✓
   Distance: Shown
   Example: "Wasser\n142m"
   ```

2. **Target Very Close (< 10m)**
   ```
   Arrow: HIDDEN ✗
   Reason: Player is close enough
   ```

3. **Target Not Found**
   ```
   Arrow: NOT SHOWN
   Example: No crystals loaded in current chunks
   ```

## Screen Layout Integration

```
┌─────────────────────────────────────────────────┐
│  [Minimap]                        [Time] [☀️]  │  ← Top-right
│                                                 │
│                                                 │
│                  [Mountain Arrow]               │
│                        ↑                        │
│                                                 │
│  [Water Arrow]                  [Crystal Arrow] │
│       ←                                →        │
│                                                 │
│                  (Game View)                    │
│                                                 │
│                                                 │
│                                                 │
│  [Joystick]                    [Action Buttons] │  ← Bottom
└─────────────────────────────────────────────────┘

Z-Index Layers:
  100: Pause Menu (highest)
   60: Direction Arrows & Minimap ← New system here
   50: Ruler Overlay
   10: Mobile Controls & Debug UI
    0: UI Manager
```

## Direction Calculation Example

```
Player Position: (0, 0, 0)
Target (Water): (100, -8, 50)

Step 1: Calculate 3D direction
  direction = normalize(target - player)
  = normalize((100, -8, 50) - (0, 0, 0))
  = normalize((100, -8, 50))
  
Step 2: Project to horizontal plane
  direction_h = (100, 0, 50) / length
  
Step 3: Convert to screen space using camera
  - Camera forward: (0, 0, -1)
  - Camera right: (1, 0, 0)
  
  screen_direction = (
    dot(direction_h, camera_right),
    -dot(direction_h, camera_forward)
  )
  
Step 4: Position on circle
  arrow_pos = screen_center + screen_direction * 150px
```

## Example Scenarios

### Scenario 1: All Targets Visible
```
Player at spawn (0, 0, 0)

Targets:
- Water:    200m northeast  → Blue arrow at 45°
- Crystal:   50m west       → Purple arrow at 270°
- Mountain: 800m south      → Gray arrow at 180°

Result: All 3 arrows visible
```

### Scenario 2: Close to Crystal
```
Player near crystal (5m away)

Targets:
- Water:    200m northeast  → Blue arrow visible
- Crystal:    5m nearby     → Purple arrow HIDDEN (< 10m)
- Mountain: 800m south      → Gray arrow visible

Result: Only 2 arrows visible
```

### Scenario 3: No Crystals Loaded
```
Player in ocean area

Targets:
- Water:     0m (player in water) → Blue arrow HIDDEN
- Crystal:  Not in loaded chunks  → Purple arrow NOT SHOWN
- Mountain: 600m north            → Gray arrow visible

Result: Only 1 arrow visible
```

## Color Reference (RGBA)

```
Water Arrow:    Color(0.2, 0.5, 1.0, 0.8)
                R: 51  (20%)
                G: 128 (50%)
                B: 255 (100%)
                A: 204 (80%)

Crystal Arrow:  Color(0.8, 0.2, 0.8, 0.8)
                R: 204 (80%)
                G: 51  (20%)
                B: 204 (80%)
                A: 204 (80%)

Mountain Arrow: Color(0.6, 0.6, 0.6, 0.8)
                R: 153 (60%)
                G: 153 (60%)
                B: 153 (60%)
                A: 204 (80%)

White Outline:  Color(1.0, 1.0, 1.0, 1.0)
                Full white, 100% opacity

Text Shadow:    Color(0.0, 0.0, 0.0, 1.0)
                Full black, for readability
```

## Performance Characteristics

```
Update Frequency:
- Target positions: Every 1 second
- Camera vectors: Every 1 second
- Visual rendering: Every frame (60 FPS)

Computational Cost per Update:
- Scan chunks for water: O(n) where n = loaded chunks (~49 chunks)
- Scan chunks for crystals: O(n*m) where m = crystals per chunk (~5)
- Mountain position: O(1) - cached from static variable

Total: ~300-500 iterations per second
       (very lightweight)
```

## Testing Checklist

When testing in-game, verify:

- [ ] Blue arrow points to nearest water
- [ ] Purple arrow points to nearest crystal
- [ ] Gray arrow points to mountain
- [ ] Arrows rotate correctly when player turns
- [ ] Distance labels update correctly
- [ ] Arrows disappear within 10m of target
- [ ] No overlap with minimap in top-right
- [ ] Arrows don't block player input
- [ ] Performance is smooth (no lag)
- [ ] German labels display correctly ("Wasser", "Kristall", "Berg")
