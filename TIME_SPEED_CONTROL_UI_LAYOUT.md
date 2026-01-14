# Time Speed Control UI Layout

This document shows the visual layout of the time speed control UI elements.

## UI Location
The time speed control is located in the **bottom-right corner** of the screen.

## Layout Diagram

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│                                                     │
│                                                     │
│                                                     │
│                                                     │
│                                                     │
│                                                     │
│                                                     │
│                                                     │
│                                                     │
│                                                     │
│                                                     │
│                                                     │
│                                                     │
│                                                     │
│                                                     │
│                                                     │
│                                                     │
│                                                     │
│                                              2x [-][+] ←─ Time speed control
│                                                14:32 ←─ In-game time clock
│                                           v1.0.24 ←─ Version label
└─────────────────────────────────────────────────────┘
```

## Component Breakdown

### From bottom to top:

1. **Version Label** (v1.0.24)
   - Color: Gray (0.7, 0.7, 0.7, 0.8)
   - Font size: 16
   - Position: 10px from right, 10px from bottom

2. **Time Label** (14:32)
   - Color: Yellowish (0.9, 0.9, 0.7, 0.9)
   - Font size: 16
   - Position: 25px above version label

3. **Time Speed Control Row**
   - Position: 50px above version label
   - Contains 3 elements:

   **a. Speed Label** (2x)
   - Color: Light green (0.7, 0.9, 0.7, 0.9)
   - Font size: 14
   - Right-aligned, leaving 60px space for buttons
   
   **b. Minus Button** (-)
   - Size: 25px × 20px
   - Position: 55px from right edge
   - Text: "-"
   - Font size: 14
   
   **c. Plus Button** (+)
   - Size: 25px × 20px (actually uses offset to edge)
   - Position: 25px from right edge
   - Text: "+"
   - Font size: 14

## Visual Representation (Actual Size Reference)

```
                                    2x  [-]  [+]
                                         ^25px^
                          ^60px space^
```

## Interaction Flow

```
User clicks [-]           User clicks [+]
     ↓                          ↓
Time scale / 2            Time scale × 2
     ↓                          ↓
Update label              Update label
     ↓                          ↓
Notify DayNightCycle      Notify DayNightCycle
     ↓                          ↓
Time slows down           Time speeds up
```

## Speed Progression Examples

### Increasing Speed (clicking +):
```
1x → 2x → 4x → 8x → 16x → 32x (max)
```

### Decreasing Speed (clicking -):
```
1x → 0.50x → 0.25x (min)
```

## Color Scheme

All time-related UI elements use warm, earthy colors that complement the day/night theme:

- **Time Clock**: Yellowish (warm, like sunlight)
- **Speed Label**: Light green (growth, progression)
- **Version**: Gray (neutral, unobtrusive)

## Z-Index Layering

All time control elements share the same z-index (50) to ensure they:
- Appear above most game elements
- Stay below debug overlay (z-index 100+)
- Stay below night overlay (z-index 200)

## Responsive Considerations

The UI elements are anchored to the bottom-right corner using:
- `anchor_left = 1.0`
- `anchor_top = 1.0`
- `anchor_right = 1.0`
- `anchor_bottom = 1.0`

This ensures the elements maintain their position relative to the bottom-right corner regardless of screen size.

## Button States

The buttons have three visual states managed by Godot's Button node:
1. **Normal**: Default appearance
2. **Hover**: Visual feedback when cursor is over button
3. **Pressed**: Visual feedback when button is clicked

**Note**: `focus_mode = FOCUS_NONE` prevents the buttons from gaining keyboard focus, ensuring they don't interfere with gameplay controls.
