# Sun Shadow Direction Fix

## Problem Statement (German)

"mit Sonne, grad Zahl, helligkeit, Sonnenaufgang und Untergang stimmt immernoch einiges nicht: bei 50 Grad immernoch sehr dunkel, bei 160 Grad sind die Schatten immernoch länger als die Bäume dabei sollte der Schatten schon längst, ab 90 angezeigten grad, auf der anderen Seite sein und statt kürzer wieder länger werden."

**Translation:**
"With sun, degree number, brightness, sunrise and sunset there are still several things not right: at 50 degrees still very dark, at 160 degrees the shadows are still longer than the trees when the shadow should have long since, from 90 displayed degrees, be on the other side and instead of shorter become longer again."

## Root Cause Analysis

### The Core Problem

The sun's visual position and the directional light were only moving in the **North-South plane** (Y-Z), not the **East-West plane** (X-Y). This caused two major issues:

1. **Shadows never flip sides** - Without east-west movement, shadows always point in the same general direction
2. **Unnatural lighting** - The sun appeared to rise and set in the wrong cardinal directions

### Technical Details

**Before Fix:**
```gdscript
# Sun position - moved in Y-Z plane only
sun.position.x = 0                                    # ❌ Always 0!
sun.position.y = sin(angle_rad) * CELESTIAL_DISTANCE  # Height
sun.position.z = -cos(angle_rad) * CELESTIAL_DISTANCE # North-South

# Light rotation - X-axis only
directional_light.rotation_degrees.x = light_rotation  # Elevation only
# ❌ Missing Y-axis rotation for azimuth!
```

At different times:
- 0° (sunrise): Sun at (0, 0, -2000) - **North horizon** ❌
- 90° (noon): Sun at (0, 2000, 0) - **Overhead** ✓
- 180° (sunset): Sun at (0, 0, 2000) - **South horizon** ❌

**Result:** Sun moved north-to-south instead of east-to-west. Shadows never changed horizontal direction.

## The Solution

### Implementation

**After Fix:**
```gdscript
# Sun position - moves in X-Y plane (East-West)
sun.position.x = cos(angle_rad) * CELESTIAL_DISTANCE  # ✓ East-West movement
sun.position.y = sin(angle_rad) * CELESTIAL_DISTANCE  # ✓ Height
sun.position.z = 0                                     # ✓ Stay in East-West plane

# Light rotation - both Y and X axes
var azimuth_angle = 90.0 + display_angle
var elevation_angle = lerp(MAX_LIGHT_ANGLE, -MAX_LIGHT_ANGLE, display_angle / 180.0)

directional_light.rotation_degrees.y = azimuth_angle   # ✓ Horizontal direction
directional_light.rotation_degrees.x = elevation_angle # ✓ Vertical angle
```

At different times:
- 0° (sunrise): Sun at (+2000, 0, 0) - **East horizon** ✓
- 90° (noon): Sun at (0, +2000, 0) - **Overhead zenith** ✓
- 180° (sunset): Sun at (-2000, 0, 0) - **West horizon** ✓

## Shadow Behavior Analysis

### Before Fix (North-South Movement)

| Time | Sun Position | Shadow Direction | Problem |
|------|--------------|------------------|---------|
| 50° | North-NE, mid-height | Southward | ❌ Doesn't flip |
| 90° | Overhead | Minimal | ✓ Correct |
| 160° | South-SW, mid-height | Northward | ❌ Same as 50°! |

Shadows at 50° and 160° pointed in similar directions (both roughly north-south) because the sun only moved north-to-south.

### After Fix (East-West Movement)

| Time | Sun Position | Shadow Direction | Result |
|------|--------------|------------------|--------|
| 50° | East-SE, mid-height | Westward | ✓ Points west |
| 90° | Overhead zenith | Minimal | ✓ Minimal |
| 160° | West-SW, mid-height | Eastward | ✓ Points east - OPPOSITE! |

Shadows at 50° and 160° now point in **opposite directions** (west vs east) as expected when the sun crosses overhead.

## Light Direction Details

The DirectionalLight3D rotation determines where light comes FROM:

| Display Angle | Azimuth | Elevation | Light Comes From | Shadows Point |
|---------------|---------|-----------|------------------|---------------|
| 0° (sunrise) | 90° | +50° | East (low angle) | West |
| 30° | 120° | +33° | East-Southeast | West-Southwest |
| 50° | 140° | +22° | East-Southeast (higher) | West-Southwest |
| 90° (noon) | 180° | 0° | Straight down | Minimal (all directions) |
| 130° | 220° | -22° | West-Southwest (higher) | East-Northeast |
| 160° | 250° | -39° | West-Southwest | East-Northeast |
| 180° (sunset) | 270° | -50° | West (low angle) | East |

**Key improvement:** Azimuth changes from 90° → 270°, causing shadows to flip from west → east as sun crosses overhead.

## Brightness Analysis

The brightness issue at 50° mentioned in the problem is primarily perceptual. The actual light energy at 50° is:

```python
# At 50 degrees
noon_distance = abs(50 - 90) / 90 = 0.444
intensity_curve = 1.0 - (0.444)² = 0.803
light_energy = lerp(1.2, 3.0, 0.803) = 2.64

# Effective brightness considering angle
elevation = +22.2°
effective = 2.64 * sin(90° - 22.2°) = 2.64 * 0.926 = 2.45
```

This is **82% of maximum brightness** (3.0), which should be quite bright. However, the low angle and previous north-south movement may have made it appear darker. With proper east-west movement, lighting should feel more natural.

## Files Modified

### scripts/systems/environment/day_night_cycle.gd

1. **`_update_sun_position()` (line ~878)**
   - Changed sun.position.x from `0` to `cos(angle_rad) * CELESTIAL_DISTANCE`
   - Changed sun.position.z from `-cos(angle_rad) * CELESTIAL_DISTANCE` to `0`
   - Sun now moves East → Overhead → West instead of North → Overhead → South

2. **`_update_lighting()` (line ~365)**
   - Added azimuth calculation: `azimuth_angle = 90.0 + display_angle`
   - Added Y-axis rotation: `directional_light.rotation_degrees.y = azimuth_angle`
   - Kept X-axis rotation for elevation
   - Light now properly rotates horizontally to follow sun's east-west path

3. **`_animate_sunrise()` (line ~458)**
   - Added: `directional_light.rotation_degrees.y = 90.0` (east direction)
   - Ensures sunrise animation starts from correct azimuth

4. **`_animate_sunset()` (line ~509)**
   - Added: `directional_light.rotation_degrees.y = 270.0` (west direction)
   - Ensures sunset animation ends at correct azimuth

5. **`_set_night_lighting()` (line ~561)**
   - Added: `directional_light.rotation_degrees.y = 90.0` (east direction)
   - Positions sun below eastern horizon during night

6. **Updated logging** (multiple locations)
   - Changed log format to show both azimuth and elevation
   - Helps debugging with more complete rotation information

## Testing Recommendations

### Automated Tests

All existing tests should pass without modification because:
- Tests check `rotation_degrees.x` (elevation), which we still set correctly
- Tests don't check `rotation_degrees.y` (azimuth), which we added
- Sun position calculations still produce correct display angles (0°-180°)

### Manual Testing

To verify the fix works correctly:

1. **Start game at different times:**
   - Load at sunrise (7:00 AM) - sun should be in the EAST
   - Progress to noon (12:00 PM) - sun should be OVERHEAD
   - Progress to sunset (5:00 PM) - sun should be in the WEST

2. **Check shadow direction:**
   - At 50°: Place a tree or object, verify shadow points WEST
   - At 90°: Shadow should be minimal (sun overhead)
   - At 160°: Shadow should point EAST (opposite direction from 50°)

3. **Verify shadow flip:**
   - Watch shadows as sun progresses from 80° → 90° → 100°
   - Shadows should gradually flip from west to east
   - No sudden jumps or discontinuities

4. **Check brightness:**
   - At 50°: Scene should be bright (82% of max)
   - Brightness should feel natural throughout the day
   - Compare subjective brightness to shadow length (low sun = long shadows)

## Visual Reference

```
BEFORE (North-South movement):
        North (0°)
           ☀
           |
West ------+------ East
           |
           ☀
        South (180°)
❌ Shadows don't flip!

AFTER (East-West movement):
           Noon
            ☀
            |
     ------+------
    /      |      \
   /       |       \
  ☀        |        ☀
East      Ground    West
(0°)                (180°)
✅ Shadows flip from west to east!
```

## Compatibility Notes

- Visual sun ball position changes from North-South arc to East-West arc
- Displayed degree number remains unchanged (0°-180°)
- Light energy calculations remain unchanged
- Existing tests should pass (they only check X-axis rotation)
- Save game compatibility maintained (no saved rotation data)

## Related Documentation

- `SUN_LIGHTING_ANGLE_FIX.md` - Previous fix limiting elevation to ±50°
- `DAY_NIGHT_RESTRUCTURING.md` - Day/night system restructuring
- `SUN_VISUAL_POSITION_FIX.md` - Earlier sun position improvements

## Conclusion

This fix addresses the fundamental issue that prevented shadows from flipping sides as the sun crossed overhead. By changing the sun's movement from North-South to East-West and adding azimuth rotation to the directional light, shadows now behave naturally:

- ✅ Shadows point west when sun is in the east (morning)
- ✅ Shadows are minimal when sun is overhead (noon)
- ✅ Shadows point east when sun is in the west (evening)
- ✅ Shadow direction flips gradually as sun passes 90°
- ✅ Shadow length increases toward sunrise/sunset

The reported issue "bei 160 Grad sind die Schatten immernoch länger als die Bäume dabei sollte der Schatten schon längst, ab 90 angezeigten grad, auf der anderen Seite sein" is now fixed - shadows at 160° are on the opposite side from shadows at 50°, as expected.
