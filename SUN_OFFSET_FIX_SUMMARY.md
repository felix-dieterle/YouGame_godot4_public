# Sun Offset Discontinuity Fix

## Problem Report (German)
"durch den sonnen offset könnte ich folgendes beobachten, zum 2:00 ist die Sonne bereits am aufgehen, Punkt 7:00 Uhr aber dann wird es in der einen Sekunde plötzlich dunkel, könnte das das Problem sein?"

**English Translation:**
"Due to the sun offset, I could observe the following: at 2:00 the sun is already rising, but at exactly 7:00 it suddenly becomes dark in one second - could that be the problem?"

## Root Cause
The `_apply_sun_time_offset()` function was applying modulo wrapping to shift the sun's position based on the user's time offset preference. When the offset caused the time ratio to wrap around (e.g., from 0.99 to 0.01), the sun's position would suddenly jump from near sunset to near sunrise, causing an abrupt change in lighting.

**Example of the bug:**
- User sets sun offset to +5 hours
- At actual time ratio 0.9 (late afternoon), offset ratio = 5/10 = 0.5
- Total ratio = 0.9 + 0.5 = 1.4
- After modulo: 1.4 % 1.0 = 0.4
- Sun jumps from evening position (0.9) to mid-morning position (0.4)
- Result: Sudden darkness at unexpected times

## Solution
The fix separates the concerns:
1. **Sun position and lighting**: Based purely on actual `current_time`, no offset applied
2. **Displayed time**: Offset applied only to the UI display

This ensures:
- Sun always moves smoothly across the sky
- Lighting transitions are gradual and predictable
- Users can still adjust what time is displayed to their preference
- No more sudden jumps or discontinuities

## Code Changes

### Before (Buggy):
```gdscript
func _update_lighting() -> void:
    var time_ratio = current_time / DAY_CYCLE_DURATION
    time_ratio = _apply_sun_time_offset(time_ratio)  # ❌ Causes discontinuity
    var sun_angle = lerp(SUNRISE_END_ANGLE, SUNSET_START_ANGLE, time_ratio)
    directional_light.rotation_degrees.x = -sun_angle
```

### After (Fixed):
```gdscript
func _update_lighting() -> void:
    var time_ratio = current_time / DAY_CYCLE_DURATION
    # NOTE: Sun offset is NOT applied to sun position - it only affects displayed time
    # This prevents discontinuities when offset wraps around day boundaries
    var sun_angle = lerp(SUNRISE_END_ANGLE, SUNSET_START_ANGLE, time_ratio)
    directional_light.rotation_degrees.x = -sun_angle
    
    # Offset is still applied to displayed time in UI
    ui_manager.update_game_time(current_time, DAY_CYCLE_DURATION, sun_time_offset_hours)
```

## Files Modified
1. **scripts/day_night_cycle.gd**: Removed offset from sun position calculations
2. **tests/test_day_night_cycle.gd**: Added comprehensive discontinuity test
3. **scripts/pause_menu.gd**: Updated UI labels to clarify offset behavior

## Testing
Added `test_sun_offset_no_discontinuity()` which verifies:
- Sun position remains constant with different offset values
- Works with positive offsets (+5 hours)
- Works with negative offsets (-3 hours)
- Works with extreme offsets (+12 hours)
- Sun progression is smooth throughout entire day (no jumps > 2°)

## User-Visible Changes
1. **Settings Menu**: Label changed from "Sun Offset:" to "Sun Offset (Display):"
2. **Tooltips**: Added explanations that offset only affects displayed time
3. **Behavior**: Sun now always moves smoothly, no sudden lighting changes

## Benefits
✅ No more sudden darkness at 7:00 AM or other times
✅ Predictable and smooth sun movement
✅ Lighting transitions are always gradual
✅ Offset feature still works for display preferences
✅ Better user understanding through clearer UI labels

## Migration Notes
- No save file changes needed
- Existing sun offset settings continue to work
- Behavior change is a bug fix, not a breaking change
- Users may notice sun position no longer jumps with offset
