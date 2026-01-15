# Visual Guide: Time Speed Control UI

## Expected Visual Appearance

This document describes how the time speed control UI will appear when the game is running.

## Screenshot Description

When players run the game, they will see the following in the **bottom-right corner** of the screen:

```
┌────────────────────────────────────────────────────────────┐
│                                                            │
│                         GAME WORLD                         │
│                      (3D Terrain View)                     │
│                                                            │
│                                                            │
│                                                            │
│                                                            │
│                                                            │
│                                                            │
│                                                            │
│                                                            │
│                                                            │
│                                                            │
│                                                            │
│                                                            │
│                                                            │
│                                                            │
│                                                     ╔══════╗
│                                                 2x  ║  -  ║  ║  +  ║
│                                                     ╚══════╝  ╚══════╝
│                                                    14:32
│                                                  v1.0.24
└────────────────────────────────────────────────────────────┘
```

## Detailed Component View

### Full UI Stack (Bottom to Top)

```
┌─────────────────────────────────────┐
│                                     │  ← Screen edge (right side)
│                   ┌──────────┐      │
│                   │   2x     │ [-] [+]  ← Time speed control row
│                   └──────────┘      │     (50px from bottom)
│                                     │
│                   ┌──────────┐      │
│                   │  14:32   │      │  ← In-game clock
│                   └──────────┘      │     (25px from bottom)
│                                     │
│                   ┌──────────┐      │
│                   │ v1.0.24  │      │  ← Version label
│                   └──────────┘      │     (10px from bottom)
│                                     │
└─────────────────────────────────────┘
    10px margin from right edge →
```

## Color and Style Details

### 1. Time Speed Label ("2x")
- **Text**: Shows current multiplier
  - ≥ 1.0: Integer format (1x, 2x, 4x, 8x, 16x, 32x)
  - < 1.0: Two decimal format (0.50x, 0.25x)
- **Font Size**: 14px
- **Color**: Light green (RGB: 0.7, 0.9, 0.7, alpha: 0.9)
  - Represents growth/progression
  - Visible against most backgrounds
- **Alignment**: Right-aligned

### 2. Minus Button (-)
- **Size**: 25px wide × 20px tall
- **Text**: Single dash "-"
- **Font Size**: 14px
- **Background**: Default Godot button style
- **Border**: Standard button border
- **States**:
  - Normal: Default appearance
  - Hover: Slight highlight
  - Pressed: Darker/pressed appearance

### 3. Plus Button (+)
- **Size**: 25px wide × 20px tall (to right edge)
- **Text**: Single plus "+"
- **Font Size**: 14px
- **Background**: Default Godot button style
- **Border**: Standard button border
- **States**:
  - Normal: Default appearance
  - Hover: Slight highlight
  - Pressed: Darker/pressed appearance

### 4. In-Game Clock ("14:32")
- **Text**: 24-hour time format (HH:MM)
- **Font Size**: 16px
- **Color**: Yellowish (RGB: 0.9, 0.9, 0.7, alpha: 0.9)
  - Warm color suggesting sunlight
  - Distinct from speed label
- **Alignment**: Right-aligned

### 5. Version Label ("v1.0.24")
- **Text**: Version number with "v" prefix
- **Font Size**: 16px
- **Color**: Gray (RGB: 0.7, 0.7, 0.7, alpha: 0.8)
  - Neutral, unobtrusive
  - Lower opacity than other elements
- **Alignment**: Right-aligned

## Spacing and Layout

```
Edge of screen (right side)
│
├─ 10px margin
│  │
│  ├─ Plus button [+] (25px wide)
│  │  │
│  │  └─ 5px gap
│  │     │
│  │     └─ Minus button [-] (25px wide)
│  │        │
│  │        └─ 5px gap
│  │           │
│  │           └─ Speed label "2x" (right-aligned)
│  │
│  └─ 25px vertical gap
│     │
│     └─ Clock "14:32" (right-aligned)
│        │
│        └─ 25px vertical gap
│           │
│           └─ Version "v1.0.24" (right-aligned)
│              │
│              └─ 10px margin from bottom
│
Bottom of screen
```

## Interactive Behavior

### Clicking the Plus (+) Button

**Before Click**: Speed = 1x
```
1x  [-]  [+]  ← User clicks here
   14:32
 v1.0.24
```

**After Click**: Speed = 2x
```
2x  [-]  [+]  ← Label updates immediately
   14:32      ← Time passes twice as fast
 v1.0.24
```

**Progression**:
```
1x → 2x → 4x → 8x → 16x → 32x (stops at max)
```

### Clicking the Minus (-) Button

**Before Click**: Speed = 2x
```
2x  [-]  [+]  ← User clicks here
   14:32
 v1.0.24
```

**After Click**: Speed = 1x
```
1x  [-]  [+]  ← Label updates immediately
   14:32      ← Time returns to normal speed
 v1.0.24
```

**Progression**:
```
1x → 0.50x → 0.25x (stops at min)
```

## Visual Feedback Examples

### At Different Speeds

**Normal Speed (1x)**:
```
1x  [-]  [+]
   14:32
```

**Double Speed (2x)**:
```
2x  [-]  [+]
   14:33  ← Time advances faster
```

**Very Fast (16x)**:
```
16x  [-]  [+]
    14:47  ← Time rushes forward
```

**Slow Motion (0.50x)**:
```
0.50x  [-]  [+]
     14:32  ← Time crawls
```

**Maximum Speed (32x)**:
```
32x  [-]  [+]  ← At maximum, + button has no effect
    15:28       ← Day passes very quickly
```

**Minimum Speed (0.25x)**:
```
0.25x  [-]  [+]  ← At minimum, - button has no effect
     14:32        ← Time moves very slowly
```

## Visibility Conditions

The time speed controls are **always visible** during gameplay, except when:
- Night overlay is active (z-index 200 covers everything)
- Pause menu is open (may cover the UI)
- Debug overlay is shown (but controls remain visible below it)

## Integration with Other UI Elements

The time speed control is positioned to:
- ✓ Not overlap with mobile touch controls (bottom-left)
- ✓ Not overlap with chunk info (top-left)
- ✓ Not overlap with status messages (top-center)
- ✓ Complement the existing time display
- ✓ Stay grouped with related time information

## Comparison: Before vs After

### Before This Feature
```
                                    14:32
                                  v1.0.24
```
*Players could only watch time pass at normal speed*

### After This Feature
```
                             2x  [-]  [+]
                                    14:32
                                  v1.0.24
```
*Players can now control time flow with interactive buttons*

## Expected User Experience

1. **Discovery**: Players notice new buttons next to the clock
2. **Experimentation**: Click + to see time speed up
3. **Understanding**: Label shows current speed multiplier
4. **Control**: Use - to slow down for sunset viewing
5. **Gameplay**: Speed up boring parts, slow down important moments

## Platform Considerations

### Desktop
- Buttons respond to mouse hover
- Click with mouse to adjust speed
- Clear visual feedback on hover

### Mobile
- Buttons sized for finger taps (25×20px may need adjustment for mobile)
- Touch to activate (no hover state)
- Positioned to avoid accidental taps

## Accessibility

- **Size**: Buttons are reasonably sized for clicking
- **Contrast**: Text colors chosen for visibility
- **Spacing**: Adequate space between buttons to prevent mis-clicks
- **Feedback**: Immediate visual update when clicked

## Performance Impact

- **UI Rendering**: Minimal (3 additional UI elements)
- **Update Frequency**: Only updates when buttons are clicked
- **Memory**: Negligible (small UI components)
- **CPU**: No continuous processing, event-driven only

---

**Note**: Since this is a Godot 4 project and we don't have the actual game running, this visual guide provides a detailed description of the expected appearance. When you run the game, the actual UI will render with Godot's default theme and may have slight variations in button styling based on the project's theme settings.
