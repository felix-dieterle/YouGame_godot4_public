# Sun 4 Hours Earlier at Game Start

## Problem Statement (German)
"lass die Sonne schon 4 Stunden früher aufgehen/es hell werden. wir starten das Spiel aber immernoch um 7:00"

**English Translation:**
"let the sun rise 4 hours earlier / make it light earlier. we still start the game at 7:00"

## Solution
Changed the `INITIAL_TIME_OFFSET_HOURS` from `0.0` to `4.0` in the DayNightCycle script.

## Implementation Details

### Code Change
**File:** `scripts/day_night_cycle.gd`

```gdscript
# Before:
const INITIAL_TIME_OFFSET_HOURS: float = 0.0  # Hours to advance sun position at game start

# After:
const INITIAL_TIME_OFFSET_HOURS: float = 4.0  # Hours to advance sun position at game start (0.0 = start at sunrise, 7:00 AM; 4.0 = sun 4 hours ahead for brighter start)
```

### How It Works
The `INITIAL_TIME_OFFSET_HOURS` variable controls the **initial sun position** at game start, while `sun_time_offset_hours` controls the **displayed time**.

With the 4-hour offset:
- The sun starts at a position as if it's 4 hours after sunrise (11:00 AM position)
- The displayed time still shows 7:00 AM (since `sun_time_offset_hours = 0.0`)
- This makes the game **brighter and more lit** from the very beginning
- The sun is higher in the sky, providing more natural daylight

### Game State Changes

| Game State | Displayed Time | Sun Position (As If) | Brightness Level |
|------------|----------------|---------------------|------------------|
| Game start | 7:00 AM | 11:00 AM | Bright daylight |
| Midpoint | 12:00 PM (noon) | 4:00 PM | Still bright |
| Day end | 5:00 PM | 9:00 PM (sunset) | Dimming |

### Lighting Changes

At game start (displayed 7:00 AM):
- **Before change**: Sun at sunrise position (-60° angle), brightness at minimum (0.8 light energy)
- **After change**: Sun at mid-morning position (-36° angle), significantly brighter (~1.76 light energy)

The intensity curve calculation:
```
time_ratio = 4.0 / 10.0 = 0.4 (40% into the day)
intensity_curve = 1.0 - abs(0.4 - 0.5) * 2.0 = 1.0 - 0.2 = 0.8
light_energy = lerp(0.8, 2.0, 0.8) = 0.8 + (2.0 - 0.8) * 0.8 = 1.76
```

## Technical Notes

### Why Use INITIAL_TIME_OFFSET_HOURS Instead of sun_time_offset_hours?

1. **INITIAL_TIME_OFFSET_HOURS**: Advances the actual sun position (affects brightness and lighting)
2. **sun_time_offset_hours**: Only changes the displayed time (purely cosmetic)

For this requirement, we need to make the game **brighter**, so we use `INITIAL_TIME_OFFSET_HOURS` to advance the sun's actual position.

### Comparison with Previous Implementations

This approach is different from the previous sun rise implementations (2 and 3 hours earlier):
- **Previous implementations** (SUN_RISE_2/3_HOURS_EARLIER.md): Changed `sun_time_offset_hours` to make the *displayed time* earlier
- **Current implementation**: Changes `INITIAL_TIME_OFFSET_HOURS` to make the *actual sun position* advanced, providing more brightness

### Impact on Game Experience

Players will now experience:
1. **Brighter game start**: The game begins with mid-morning lighting instead of sunrise lighting
2. **Higher sun position**: Sun is higher in the sky, providing better visibility
3. **More natural daylight**: The lighting feels like a typical day rather than early morning
4. **Same time display**: Clock still shows 7:00 AM at start (as requested)
5. **Shorter subjective day**: Since the sun starts 4 hours ahead, the day feels shorter (only 6 hours of daylight left instead of 10)

### Backwards Compatibility
- ✅ Existing save files continue to work (they store `current_time` which will be loaded)
- ✅ Tests that explicitly set time values remain unaffected
- ✅ Players can still adjust time settings in the pause menu
- ⚠️ Fresh starts will now begin with brighter lighting (this is the intended change)

## User Experience

Before this change:
- Game started at sunrise with dim lighting
- Took time to reach comfortable brightness

After this change:
- Game starts with bright, comfortable lighting immediately
- Better visibility and more pleasant starting experience
- Still shows 7:00 AM on the clock (as requested)

## Files Modified
- `scripts/day_night_cycle.gd` - Changed INITIAL_TIME_OFFSET_HOURS from 0.0 to 4.0
- Updated comment on line 436 to reflect new behavior

## Related Documentation
- `SUN_RISE_3_HOURS_EARLIER.md` - Previous implementation (display time offset)
- `SUN_RISE_2_HOURS_EARLIER.md` - Earlier implementation (display time offset)
- `SUN_OFFSET_FIX_SUMMARY.md` - Explains offset system design
- `docs/systems/DAY_NIGHT_CYCLE.md` - Day/night cycle system overview

## Testing
To verify this change:
1. Start a new game (delete save files)
2. Observe the lighting at game start - should be bright and mid-morning quality
3. Check the displayed time - should show 7:00 AM
4. Observe the sun position in the sky - should be higher than before
