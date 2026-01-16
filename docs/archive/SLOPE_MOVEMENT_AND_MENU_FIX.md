# Slope Movement and Menu Button Fix

## Problem Statement (German)
> die Grenze an Steigung bei 30% macht aktuellen Problem bei der komplett stehen bleibt und in keine Richtung mehr sich bewegt. wie begegnet man normalerweise diesem Problem? weil er soll der rückwärts trotzdem noch laufen können oder seitwärts, solange es nicht in echt in dieser Steigung geht. außerdem mein Vorschlag bezüglich dem Menü Button, der immer noch nicht erscheint. vielleicht können wir ihn einfach links oben platzieren, neben die anderen Buttons vom debug Fenster

**Translation**: The 30% slope limit currently causes a problem where [the player] stops completely and can't move in any direction. How do you normally deal with this problem? Because they should still be able to move backwards or sideways, as long as they're not actually going up the slope. Also, my suggestion regarding the menu button that still doesn't appear: maybe we can just place it in the top left, next to the other debug window buttons.

## Solutions Implemented

### 1. Slope Movement Fix

**Previous Behavior**: When the player encountered a slope > 30°, ALL movement was blocked, even sideways or backwards.

**New Behavior**: The player can now move sideways or backwards on steep slopes. Only movement directly uphill is blocked.

#### Implementation Details

The fix involves checking the direction of movement relative to the slope gradient:

1. **Added `get_slope_gradient_at_world_pos()` to `chunk.gd`**:
   - Calculates the gradient vector (direction of steepest ascent) at any position
   - Returns `Vector3(dx, 0, dz)` where dx and dz are height changes per unit distance

2. **Added `get_slope_gradient_at_position()` to `world_manager.gd`**:
   - Provides easy access to slope gradient from any world position
   - Returns `Vector3.ZERO` for positions outside loaded chunks

3. **Modified player movement in `player.gd`**:
   - When a slope > 30° is detected at the intended position:
     - Get the slope gradient (direction uphill)
     - Calculate dot product between movement direction and gradient
     - Only block movement if dot product > 0.1 (moving uphill)
     - Allow movement if dot product ≤ 0.1 (sideways or downhill)

#### Code Example
```gdscript
# In player.gd
if slope_at_position > max_slope_angle:
    var slope_gradient = world_manager.get_slope_gradient_at_position(intended_position)
    
    if slope_gradient.length_squared() > 0.0001:
        var normalized_gradient = slope_gradient.normalized()
        var uphill_component = direction.dot(normalized_gradient)
        
        # Only block if moving uphill
        if uphill_component > 0.1:
            can_move = false
```

#### Why This Works

The **dot product** between two normalized vectors tells us:
- `> 0`: Vectors point in similar directions (moving uphill)
- `≈ 0`: Vectors are perpendicular (moving sideways)
- `< 0`: Vectors point in opposite directions (moving downhill)

By using a threshold of 0.1, we:
- Block movement when significantly moving uphill
- Allow movement when going sideways or at slight angles
- Allow movement when going downhill

### 2. Menu Button Repositioning

**Previous Location**: Bottom-right corner (next to joystick)
**New Location**: Top-left corner (next to debug overlay buttons)

#### Changes Made

1. **Updated `_update_button_position()` in `mobile_controls.gd`**:
   ```gdscript
   # Old position (bottom-right)
   var button_x = viewport_size.x - button_margin_x - BUTTON_SIZE
   var button_y = viewport_size.y - joystick_margin_y - (BUTTON_SIZE / 2)
   
   # New position (top-left)
   var button_x = 100.0  # Right of debug buttons
   var button_y = 10.0   # Small margin from top
   ```

2. **Updated `_update_settings_panel_position()` in `mobile_controls.gd`**:
   - Panel now appears below the menu button in top-left area
   - Position: 10px from left, 70px from top (below menu button)

#### Visual Layout

```
┌─────────────────────────────────────┐
│ [📋] [🗑] [☰]                       │ ← Top-left: Debug + Menu buttons
│                                     │
│ [Settings Panel]                    │ ← Appears below menu button when opened
│ • Toggle Camera View                │
│ • Close                             │
│                                     │
│                                     │
│                                     │
│                                     │
│                                     │
│ (o)                                 │ ← Bottom-left: Joystick
└─────────────────────────────────────┘
```

## Testing

Added comprehensive tests in `test_slope_weather.gd`:

1. **`test_slope_gradient()`**: Tests gradient calculation returns valid Vector3 values
2. **Gradient via WorldManager**: Tests integration with world manager
3. **Edge cases**: Tests positions outside chunks return Vector3.ZERO

## Files Modified

- `scripts/chunk.gd`: Added `get_slope_gradient_at_world_pos()` method
- `scripts/world_manager.gd`: Added `get_slope_gradient_at_position()` method
- `scripts/player.gd`: Modified slope checking logic with gradient-based movement restriction
- `scripts/mobile_controls.gd`: Updated menu button and settings panel positioning
- `tests/test_slope_weather.gd`: Added tests for slope gradient functionality

## Benefits

1. **More Natural Movement**: Players can navigate around steep slopes instead of being completely stuck
2. **Better UX**: Menu button is now more accessible in top-left corner
3. **Consistent with Game Design**: Slope restriction only applies when trying to climb directly uphill
4. **Maintains Safety**: Still prevents unrealistic climbing of steep slopes

## Technical Notes

- The gradient calculation uses first-order finite differences
- Dot product threshold of 0.1 allows for slight uphill angles while blocking steep climbs
- Menu button z-index (101) ensures it renders above debug overlay (99-100)
- Settings panel z-index (200) ensures it appears on top when opened
