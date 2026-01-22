# Sun Display Fix and Button Overlap Fix

## Problem Statement (German)
"Warum scheint die Sonne erst bei etwa angezeigten 70-80 ° aufzugehen? Ausserdem überlagert der Menü Button den dritten (grünen) Button oben links."

**English Translation:**
"Why does the sun only rise at approximately 70-80° displayed? Also, the menu button overlaps the third (green) button in the top left."

## Issues Identified

### Issue 1: Sun Display Shows 72° at Game Start
**Root Cause:**
- The game has `INITIAL_TIME_OFFSET_HOURS = 4.0` to make the game start brighter (sun 4 hours into the day)
- At game start: `current_time = DAY_CYCLE_DURATION * (4.0 / 10.0) = 0.4 * DAY_CYCLE_DURATION`
- The old `get_sun_position_degrees()` calculated: `time_ratio = 0.4`, which displayed as `0.4 * 180 = 72°`
- Players expected to see 0° at game start, not 72°

**Impact:**
- Confusing UX: Players see the sun already high in the sky with display showing 72°
- The display doesn't match player expectations (sunrise should be 0°)

### Issue 2: Menu Button Overlaps Debug Button
**Root Cause:**
- Debug buttons are positioned at x=10, 55, 100 (three buttons: toggle, clear, copy)
- Menu button was positioned at x=100, overlapping with the third debug button (green copy button)
- Calculation error: Comment said "debug buttons take ~90px" but actually take 140px

**Impact:**
- UI overlap makes both buttons hard to click
- Visual confusion for users

## Solutions Implemented

### Solution 1: Fix Sun Position Display
Modified `scripts/day_night_cycle.gd::get_sun_position_degrees()` to:

1. Calculate the initial offset time in the day cycle
2. Map the remaining playable day (from offset to sunset) to 0-180° range
3. Add division-by-zero protection for edge cases
4. Clamp result to 0.0-1.0 to handle any edge cases

**Code Changes:**
```gdscript
# Old calculation (incorrect)
time_ratio = current_time / DAY_CYCLE_DURATION
return time_ratio * 180.0

# New calculation (correct)
var initial_offset_time = DAY_CYCLE_DURATION * (INITIAL_TIME_OFFSET_HOURS / DAY_DURATION_HOURS)
var remaining_day_duration = DAY_CYCLE_DURATION - initial_offset_time

if remaining_day_duration > 0.0:
    time_ratio = (current_time - initial_offset_time) / remaining_day_duration
else:
    time_ratio = 1.0

time_ratio = clamp(time_ratio, 0.0, 1.0)
return time_ratio * 180.0
```

**Result:**
| Game State | Old Display | New Display | Description |
|------------|-------------|-------------|-------------|
| Game start | 72° | 0° | Beginning of playable day |
| 25% through playable day | 99° | 45° | Mid-morning |
| 50% through playable day | 126° | 90° | Noon/zenith |
| 75% through playable day | 153° | 135° | Afternoon |
| Day end | 180° | 180° | Sunset |

### Solution 2: Fix Menu Button Position
Modified `scripts/mobile_controls.gd::_update_button_position()` to:

1. Correctly calculate debug button width (140px total)
2. Position menu button at x=150 (140px + 10px spacing)

**Code Changes:**
```gdscript
# Old position (incorrect)
var button_x = 100.0  # Overlaps with third debug button

# New position (correct)
var button_x = 150.0  # 140px for debug buttons + 10px spacing
```

**Result:**
- Debug buttons: x=10 (toggle), x=55 (clear), x=100 (copy)
- Menu button: x=150 (no overlap)
- Clear 10px spacing between copy button and menu button

## Technical Details

### Sun Position Display Logic
The fix preserves the internal sun positioning (for lighting calculations) while adjusting only the display:

1. **Internal sun position** (for lighting): Unchanged, starts at 4 hours into day for better brightness
2. **Display sun position**: Now shows 0° at game start for intuitive UX

This separation ensures:
- Game still starts bright (internal sun at 4h position)
- Display shows intuitive 0° at start
- No changes to lighting, brightness, or gameplay
- Display progresses smoothly from 0° to 180° over the playable day

### Edge Case Handling
The fix includes robust edge case handling:

1. **Division by zero**: Checks if `remaining_day_duration > 0.0` before division
2. **Negative ratio**: Clamps result to ensure `0.0 <= time_ratio <= 1.0`
3. **Offset >= day duration**: Returns 1.0 (end of day) if offset is too large
4. **Night mode**: Returns -1.0 to indicate sun is not visible

## Testing

### Manual Verification Steps
To verify the fixes:

1. **Sun Display Fix:**
   - Start a new game (delete save files)
   - Check that sun position display shows "Sun: 0°" at game start
   - Verify it progresses to "Sun: 90°" at midday
   - Verify it reaches "Sun: 180°" at sunset

2. **Button Overlap Fix:**
   - Launch the game on mobile or with mobile controls enabled
   - Check that menu button (☰) is clearly visible and separate from debug buttons
   - Verify no overlap between menu button and copy button (📄)
   - Verify both buttons are clickable without interference

### Expected Behavior
- [x] Sun display shows 0° at fresh game start
- [x] Sun display progresses from 0° to 180° during the day
- [x] Internal sun position (lighting) unchanged
- [x] Menu button at x=150 with no overlap
- [x] Debug buttons remain at x=10, 55, 100
- [x] Clear 10px spacing between buttons

## Files Modified
1. `scripts/day_night_cycle.gd` - Fixed `get_sun_position_degrees()` function
2. `scripts/mobile_controls.gd` - Fixed `_update_button_position()` function

## Backwards Compatibility
- ✅ Existing save files continue to work
- ✅ Internal sun position calculations unchanged (lighting preserved)
- ✅ Only affects display values, not gameplay
- ✅ No breaking changes to API or behavior

## User-Visible Changes
1. **Sun Display**: Shows 0° at game start instead of 72°, making the display intuitive
2. **UI Layout**: Menu button no longer overlaps with debug copy button

## Related Documentation
- `SUN_4_HOURS_EARLIER_AT_START.md` - Documents the INITIAL_TIME_OFFSET_HOURS feature
- `SUN_OFFSET_FIX_SUMMARY.md` - Explains sun offset system design
- `SUN_POSITION_DISPLAY.md` - Original sun position display implementation
- `docs/systems/DAY_NIGHT_CYCLE.md` - Day/night cycle system overview

## Benefits
✅ Intuitive sun position display (0° at start, 180° at end)
✅ Clear separation of display vs. internal sun position
✅ Fixed UI button overlap issue
✅ Better UX with clearer visual feedback
✅ Robust edge case handling
✅ Preserves existing brightness behavior
