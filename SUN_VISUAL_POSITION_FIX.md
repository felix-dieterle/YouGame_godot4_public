# Sun Visual Position Fix - January 2026

## Problem Statement (Original German)
"licht Problematik, some scheint elend lange auszugehen, bis 180 angezeigt wird aber eine scheinbar nur auf 90 Grad, dh am höchsten steht(gemäß der Schatten) dann blitzschnell von 90 auf 180 gemäß Schatten und schlafenszeit da+ dunkel. was läuft da schief"

**Translation:**
"Light problem, the sun seems to take endlessly long to go out, until 180 is displayed but the sun apparently only stands at 90 degrees, i.e. at the highest point (according to the shadows), then lightning fast from 90 to 180 according to shadows and sleep time there + dark. what's going wrong"

## Root Cause

The game had a mismatch between the displayed sun position and the actual visual sun position:

### Before the Fix
- **Display angle**: 0° to 180° (shown in UI as "Sun: XX°")
- **Actual sun angle**: -20° to +20° (used for positioning and lighting)
- **Visual elevation**: 90° + sun_angle = **70° to 110°**

This meant:
1. At game start: Display shows 0°, but sun is at 70° elevation (already high in sky)
2. At noon: Display shows 90°, sun is at 90° elevation (zenith) ✓
3. At sunset: Display shows 180°, but sun is only at 110° elevation (still high, just past zenith)

The sun appeared to barely move visually (only from 70° to 110°, a 40° arc) while the display showed a full 180° progression. From the player's perspective:
- The sun seemed stuck near zenith (90°) for most of the day
- Then suddenly jumped from 90° to below horizon when sunset triggered
- The shadows didn't match the displayed sun position

## Solution

Changed all sun position calculations to use the **display angle (0-180°)** instead of the internal sun angle (-20° to +20°):

### After the Fix
- **Display angle**: 0° to 180° (shown in UI)
- **Visual elevation**: 0° to 180° (direct mapping)
- **Light rotation**: 90° - display_angle (90° at sunrise, 0° at noon, -90° at sunset)

Now:
1. At game start (0°): Sun at horizon in the east, light from low angle
2. At noon (90°): Sun at zenith overhead, light from directly above
3. At sunset (180°): Sun at horizon in the west, light from low angle

The sun now travels in a full arc from horizon to horizon, matching the displayed position!

## Technical Changes

### 1. _update_lighting() function
**Before:**
```gdscript
var time_ratio = current_time / DAY_CYCLE_DURATION
var sun_angle = lerp(SUNRISE_END_ANGLE, SUNSET_START_ANGLE, time_ratio)
directional_light.rotation_degrees.x = -sun_angle
```

**After:**
```gdscript
var display_angle = get_sun_position_degrees()
var light_rotation = 90.0 - display_angle
directional_light.rotation_degrees.x = light_rotation
```

### 2. _update_sun_position() function
**Before:**
```gdscript
var sun_angle = _calculate_current_sun_angle()
var elevation_angle = 90.0 + sun_angle
```

**After:**
```gdscript
var display_angle = get_sun_position_degrees()
var elevation_angle = display_angle
```

### 3. _update_moon_position() function
**Before:**
```gdscript
var sun_angle = _calculate_current_sun_angle()
var moon_angle = sun_angle + 180.0
var elevation_angle = 90.0 + moon_angle
```

**After:**
```gdscript
var sun_display_angle = get_sun_position_degrees()
var moon_angle = sun_display_angle + 180.0
# Handle wrapping for angles > 180°
```

### 4. Animation functions
Updated sunrise/sunset animations to use absolute light rotations:
- Sunrise: +120° to +90° (below horizon to horizon)
- Sunset: -90° to -120° (horizon to below horizon)
- Night: +120° (below horizon in east)

## Benefits

✅ **Visual consistency**: Sun position in sky matches displayed angle
✅ **Correct shadows**: Shadows now accurately reflect sun position throughout the day
✅ **Full sun arc**: Sun travels from horizon to horizon, not just near zenith
✅ **Intuitive UX**: What players see matches what the UI displays
✅ **Smooth progression**: No more sudden jumps in sun/shadow position

## Testing Verification

Expected behavior after fix:

| Display Angle | Light Rotation | Sun Elevation | Description |
|---------------|----------------|---------------|-------------|
| 0° | +90° | 0° (horizon) | Sunrise - sun low in east |
| 45° | +45° | 45° | Morning - sun rising |
| 90° | 0° | 90° (zenith) | Noon - sun overhead |
| 135° | -45° | 135° | Afternoon - sun descending |
| 180° | -90° | 180° (horizon) | Sunset - sun low in west |

## Files Modified
- `scripts/day_night_cycle.gd`

## Backwards Compatibility
- ✅ No changes to save format
- ✅ No changes to external API
- ✅ Existing constants preserved (may be unused but kept for compatibility)
- ✅ Display calculations unchanged (still uses INITIAL_TIME_OFFSET_HOURS)

## Related Documentation
- `SUN_POSITION_DISPLAY.md` - Original sun position display implementation
- `SUN_DISPLAY_FIX_AND_BUTTON_OVERLAP.md` - Previous fix for display offset
- `SONNENAUFGANG_FIX.md` - Previous brightness fix (now superseded)
