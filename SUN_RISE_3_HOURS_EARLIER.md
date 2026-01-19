# Sun Rise 3 Hours Earlier Implementation

## Problem Statement (German)
"kann die Sonne bitte 3 Stunden früher aufgehen?"

**English Translation:**
"Can the sun please rise 3 hours earlier?"

## Solution
Changed the default `sun_time_offset_hours` from `0.0` to `-3.0` in the DayNightCycle script.

## Implementation Details

### Code Change
**File:** `scripts/day_night_cycle.gd`

```gdscript
# Before:
var sun_time_offset_hours: float = 0.0

# After:
var sun_time_offset_hours: float = -3.0  # Offset in hours to adjust displayed time (negative = earlier, positive = later)
```

### How It Works
The `sun_time_offset_hours` variable affects only the **displayed time** in the game UI, not the actual sun position or lighting behavior. This is an intentional design to prevent discontinuities in sun movement (see `SUN_OFFSET_FIX_SUMMARY.md`).

With the -3 hour offset:
- The time display calculation in `ui_manager.gd` subtracts 3 hours (180 minutes) from the base time
- This shifts all displayed times 3 hours earlier

### Time Display Changes

| Actual Game State | Old Display Time | New Display Time |
|-------------------|------------------|------------------|
| Day start (sunrise complete) | 7:00 AM | 4:00 AM |
| Sun at zenith (noon) | 12:00 PM | 9:00 AM |
| Day end (sunset start) | 5:00 PM | 2:00 PM |

## Technical Notes

### Why Only Display Time?
The offset affects only the displayed time because:
1. Prevents sun position discontinuities when offset wraps around day boundaries
2. Maintains smooth, predictable lighting transitions
3. Ensures the actual sun movement and lighting remain physically correct
4. Allows players to customize time display without breaking game mechanics

### Calculation Example
At the start of day (time_ratio = 0):
```
base_minutes = 0 * 10.0 * 60.0 = 0 minutes
+ SUNRISE_TIME_MINUTES = 420 minutes (7:00 AM)
+ offset = -3.0 * 60.0 = -180 minutes
= 240 minutes = 4:00 AM
```

### Backwards Compatibility
- ✅ Existing save files continue to work
- ✅ No changes to sun position or lighting behavior
- ✅ Tests explicitly set their own offset values, so they remain unaffected
- ✅ Players can still adjust the offset in settings if desired

## User Experience

Players will now experience:
1. **Earlier sunrise display**: Game shows 4:00 AM when day starts (instead of 7:00 AM)
2. **Earlier time throughout day**: All times are 3 hours earlier than before
3. **Same visual experience**: Sun position, lighting, and day/night cycle remain unchanged
4. **Customizable**: Users can still adjust this offset in the pause menu settings

## Files Modified
- `scripts/day_night_cycle.gd` - Changed default sun_time_offset_hours to -3.0

## Related Documentation
- `SUN_OFFSET_FIX_SUMMARY.md` - Explains why offset only affects display
- `docs/systems/DAY_NIGHT_CYCLE.md` - Day/night cycle system overview
- `docs/archive/BRIGHTNESS_IMPROVEMENTS.md` - Previous timing improvements
