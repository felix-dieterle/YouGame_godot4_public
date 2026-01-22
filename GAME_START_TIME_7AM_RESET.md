# Game Start Time Reset to 7:00 AM (Sunrise)

## Problem Statement (German)
"können wir das Spiel wieder um 7:00 Uhr beginnen lassen?"

**English Translation:**
"Can we make the game start again at 7:00 o'clock?"

## Solution
Reset the game start time to 7:00 AM at sunrise by changing `INITIAL_TIME_OFFSET_HOURS` from `4.0` back to `0.0`.

## Implementation Details

### Code Changes
**File:** `scripts/day_night_cycle.gd`

```gdscript
# Before:
const INITIAL_TIME_OFFSET_HOURS: float = 4.0  # Hours to advance sun position at game start

# After:
const INITIAL_TIME_OFFSET_HOURS: float = 0.0  # Hours to advance sun position at game start (0.0 = start at sunrise, 7:00 AM)
```

### How It Works
The `INITIAL_TIME_OFFSET_HOURS` constant controls the initial sun position and time when starting a new game.

**Before this change (INITIAL_TIME_OFFSET_HOURS = 4.0):**
- Game started with sun 4 hours into the day cycle
- Displayed time: 11:00 AM
- Sun position: Mid-morning (bright daylight)
- Lighting: Very bright from the start

**After this change (INITIAL_TIME_OFFSET_HOURS = 0.0):**
- Game starts at the beginning of the day cycle
- Displayed time: 7:00 AM
- Sun position: At sunrise (on the horizon)
- Lighting: Dawn/sunrise lighting

### Time Display Calculation

At game start with new values:
```
current_time = DAY_CYCLE_DURATION * (0.0 / 10.0) = 0 seconds
time_ratio = 0.0 / 5400 = 0.0
total_minutes = (0.0 * 10.0 * 60.0) + 420 + 0 = 420 minutes = 7:00 AM
```

With previous values (for comparison):
```
current_time = DAY_CYCLE_DURATION * (4.0 / 10.0) = 2160 seconds
time_ratio = 2160 / 5400 = 0.4
total_minutes = (0.4 * 10.0 * 60.0) + 420 + 0 = 660 minutes = 11:00 AM
```

## User Experience

### What Changed
Players will now experience:
1. **Game starts at 7:00 AM**: Both display time and actual sun position match
2. **Sunrise lighting**: Game begins with beautiful sunrise/dawn lighting
3. **Full day experience**: Players get the complete 10-hour day cycle (7 AM to 5 PM)
4. **Classic sunrise**: Sun starts at the horizon and rises through the day

### Comparison

| Aspect | Before (4.0 offset) | After (0.0 offset) |
|--------|--------------------|--------------------|
| Start time display | 11:00 AM | 7:00 AM |
| Sun position | Mid-morning | Sunrise/horizon |
| Initial brightness | Very bright | Dawn lighting |
| Day duration left | 6 hours | 10 hours |
| Experience | Quick bright start | Full day cycle |

## Backwards Compatibility
- ✅ Existing save files continue to work (they store their own `current_time` value)
- ✅ Players with saved games will continue from their saved time
- ✅ Only affects fresh game starts (new players or deleted save files)
- ✅ Tests calculate expected values dynamically, so they remain valid

## Technical Notes

### Why This Approach?
This change reverts to the original game design where players experience the full day cycle from sunrise (7:00 AM) through to sunset (5:00 PM). The previous 4-hour offset was introduced to provide brighter lighting at game start, but this request indicates a preference for the traditional sunrise experience.

### Alternative Considered
We could have used `sun_time_offset_hours` to change only the displayed time, but that would have created a disconnect between the displayed time and the actual sun position/lighting. Using `INITIAL_TIME_OFFSET_HOURS` ensures the time display, sun position, and lighting all align correctly.

## Files Modified
- `scripts/day_night_cycle.gd` - Changed INITIAL_TIME_OFFSET_HOURS from 4.0 to 0.0
- Updated comment on line 12 to reflect new default behavior
- Updated comment on line 435-436 to explain the new behavior

## Related Documentation
- `SUN_4_HOURS_EARLIER_AT_START.md` - Previous implementation (4 hours ahead)
- `GAME_START_TIME_RESET.md` - Earlier reset to 7:00 AM from other offsets
- `SUN_OFFSET_FIX_SUMMARY.md` - Explains the offset system
- `docs/systems/DAY_NIGHT_CYCLE.md` - Day/night cycle system overview

## Testing
Since Godot is not available in the CI environment, manual testing is recommended:
1. Delete save files: `user://day_night_save.cfg` and `user://game_save.cfg`
2. Start a new game
3. Verify the displayed time shows 7:00 AM
4. Verify the sun is at the horizon (sunrise position)
5. Verify the lighting has a dawn/sunrise quality
6. Watch the sun rise through the morning
