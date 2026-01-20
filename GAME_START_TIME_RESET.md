# Game Start Time Reset to 7:00 AM

## Problem Statement (German)
"lass das Spiel wieder bei 7:00 starten"

**English Translation:**
"Let the game start again at 7:00"

## Solution
Reset the game to start at 7:00 AM by reverting both the sun time offset and initial time offset to their default values.

## Implementation Details

### Code Changes
**File:** `scripts/day_night_cycle.gd`

```gdscript
# Before:
const INITIAL_TIME_OFFSET_HOURS: float = 3.0
var sun_time_offset_hours: float = -5.0

# After:
const INITIAL_TIME_OFFSET_HOURS: float = 0.0
var sun_time_offset_hours: float = 0.0
```

### How It Works
1. **INITIAL_TIME_OFFSET_HOURS**: Controls the actual sun position when the game starts
   - Was 3.0 (sun 3 hours into the day cycle)
   - Now 0.0 (sun at sunrise position)

2. **sun_time_offset_hours**: Controls the displayed time offset
   - Was -5.0 (display time 5 hours earlier)
   - Now 0.0 (no offset)

### Time Display Changes

| Game State | Previous Display | New Display | Change |
|------------|------------------|-------------|--------|
| Game start (fresh start) | 5:00 AM | 7:00 AM | +2 hours |
| After sunrise animation | 2:00 AM | 7:00 AM | +5 hours |
| Sun at zenith (noon) | 7:00 AM | 12:00 PM | +5 hours |
| Day end (sunset start) | 12:00 PM | 5:00 PM | +5 hours |

## Calculation Example

At game start with new values:
```
time_ratio = 0.0 * (0.0 / 10.0) = 0.0
total_minutes = 0.0 * 10.0 * 60.0 + 420 + 0.0 * 60.0
             = 0 + 420 + 0
             = 420 minutes
             = 7:00 AM
```

## User Experience

Players will now experience:
1. **Game starts at 7:00 AM**: Fresh game starts display 7:00 AM on the clock
2. **Sun at sunrise position**: The sun is at the horizon/sunrise position, providing morning lighting
3. **Standard time progression**: Times match the traditional day cycle (7 AM to 5 PM)
4. **Consistent with original design**: Returns to the original game design

## Backwards Compatibility
- ✅ Existing save files continue to work (they store their time values)
- ✅ Players with saved games will continue from their saved time
- ✅ Only affects fresh game starts
- ✅ Tests still pass (they calculate expected values dynamically)

## Files Modified
- `scripts/day_night_cycle.gd` - Reset INITIAL_TIME_OFFSET_HOURS to 0.0 and sun_time_offset_hours to 0.0
- `tests/test_day_night_cycle.gd` - Updated comment to reflect new default values

## Related Documentation
- `SUN_RISE_2_HOURS_EARLIER.md` - Previous implementation (2 hours earlier than default)
- `SUN_RISE_3_HOURS_EARLIER.md` - Previous implementation (3 hours earlier than default)
- `SUN_OFFSET_FIX_SUMMARY.md` - Explains why offset only affects display
- `docs/systems/DAY_NIGHT_CYCLE.md` - Day/night cycle system overview
