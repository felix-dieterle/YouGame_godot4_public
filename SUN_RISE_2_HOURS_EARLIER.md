# Sun Rise 2 Hours Earlier Implementation

## Problem Statement (German)
"die Sonne soll nochmal 2 Stunden vorher aufgehen relativ zur jetzigen Uhrzeit"

**English Translation:**
"The sun should rise 2 hours earlier relative to the current time"

## Solution
Changed the default `sun_time_offset_hours` from `-3.0` to `-5.0` in the DayNightCycle script.

## Implementation Details

### Code Change
**File:** `scripts/day_night_cycle.gd`

```gdscript
# Before:
var sun_time_offset_hours: float = -3.0

# After:
var sun_time_offset_hours: float = -5.0  # Offset in hours to adjust displayed time (negative = earlier, positive = later)
```

### How It Works
The `sun_time_offset_hours` variable affects only the **displayed time** in the game UI, not the actual sun position or lighting behavior. This is an intentional design to prevent discontinuities in sun movement (see `SUN_OFFSET_FIX_SUMMARY.md`).

With the -5 hour offset:
- The time display calculation in `ui_manager.gd` subtracts 5 hours (300 minutes) from the base time
- This shifts all displayed times 5 hours earlier than the default

### Time Display Changes

| Actual Game State | Previous Display (offset = -3h) | New Display (offset = -5h) | Change |
|-------------------|----------------------------------|----------------------------|---------|
| Day start (sunrise complete) | 4:00 AM | 2:00 AM | -2 hours |
| Sun at zenith (noon) | 9:00 AM | 7:00 AM | -2 hours |
| Day end (sunset start) | 2:00 PM | 12:00 PM (noon) | -2 hours |

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
+ offset = -5.0 * 60.0 = -300 minutes
= 120 minutes = 2:00 AM
```

At noon (time_ratio = 0.5):
```
base_minutes = 0.5 * 10.0 * 60.0 = 300 minutes
+ SUNRISE_TIME_MINUTES = 420 minutes (7:00 AM)
+ offset = -5.0 * 60.0 = -300 minutes
= 420 minutes = 7:00 AM
```

### Backwards Compatibility
- ✅ Existing save files continue to work (they store the time_scale and time_offset values)
- ✅ No changes to sun position or lighting behavior
- ✅ Tests explicitly set their own offset values, so they remain unaffected
- ✅ Players can still adjust the offset in settings if desired

## User Experience

Players will now experience:
1. **Earlier sunrise display**: Game shows 2:00 AM when day starts (was 4:00 AM, down from 7:00 AM default)
2. **Earlier time throughout day**: All times are 5 hours earlier than default (2 hours earlier than before)
3. **Same visual experience**: Sun position, lighting, and day/night cycle remain unchanged
4. **Customizable**: Users can still adjust this offset in the pause menu settings

## Files Modified
- `scripts/day_night_cycle.gd` - Changed default sun_time_offset_hours from -3.0 to -5.0

## Related Documentation
- `SUN_RISE_3_HOURS_EARLIER.md` - Previous implementation (3 hours earlier)
- `SUN_OFFSET_FIX_SUMMARY.md` - Explains why offset only affects display
- `docs/systems/DAY_NIGHT_CYCLE.md` - Day/night cycle system overview
- `docs/archive/BRIGHTNESS_IMPROVEMENTS.md` - Previous timing improvements
