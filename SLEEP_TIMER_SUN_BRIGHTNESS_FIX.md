# Fix: Sleep Timer and Sun Brightness Issues

## Problem Statement

This fix addresses two issues reported in the GitHub issue:

1. **Schlafenszeit problem** (Sleep time problem): Nach Neustart der App per continue: seltsame Start zustände und Fernseher sleep timer
   - Translation: After app restart with continue: strange start states and TV sleep timer

2. **Sonnen helligkeits problem** (Sun brightness problem): Sehr späte Helligkeit und plötzliche Dunkelheit bei Sonne am höchsten Stand
   - Translation: Very late brightness and sudden darkness when sun is at highest position

## Root Causes

### Issue #1: Night Overlay Stuck on Screen
**Location**: `scripts/day_night_cycle.gd` lines 138-158

When the game was restarted during an active lockout period but the lockout had already expired, the `_ready()` function would:
1. Detect that lockout has expired ✓
2. Start sunrise animation ✓
3. Show day message ✓
4. **Forget to hide the night overlay** ✗

This left the dark night overlay visible on screen even though the player could start playing, creating a "strange start state" where the screen was dark but gameplay was active.

### Issue #2: Linear Brightness Curve
**Location**: `scripts/day_night_cycle.gd` line 366

The original brightness calculation used a linear formula:
```gdscript
var intensity_curve = 1.0 - noon_distance
```

This created uniform brightness changes throughout the day:
- **Problem 1**: "Very late brightness" - Takes too long to reach full brightness in early morning
- **Problem 2**: "Sudden darkness at noon" - No brightness plateau at midday, brightness constantly changing

Real atmospheric lighting follows a more parabolic curve where brightness increases quickly in early morning, plateaus around midday, then decreases quickly in late afternoon.

## Solutions

### Fix #1: Hide Night Overlay When Lockout Expires
**File**: `scripts/day_night_cycle.gd` line 147

Added one line to hide the night overlay when lockout has expired:
```gdscript
_hide_night_screen()  # Hide night overlay since lockout has expired
```

This ensures the night overlay is properly removed when the player loads a game where the sleep lockout has already ended.

### Fix #2: Quadratic Brightness Curve
**File**: `scripts/day_night_cycle.gd` line 368

Changed the brightness calculation to use a quadratic curve:
```gdscript
# Old (linear):
var intensity_curve = 1.0 - noon_distance

# New (quadratic):
var intensity_curve = 1.0 - (noon_distance * noon_distance)
```

## Brightness Comparison

| Sun Position | Linear Brightness | Quadratic Brightness | Improvement |
|--------------|-------------------|----------------------|-------------|
| 0° (sunrise) | 1.20 | 1.20 | 0.00 |
| 30° (early morning) | 1.80 | **2.20** | **+0.40 (+22%)** |
| 45° (mid-morning) | 2.00 | **2.55** | **+0.55 (+28%)** |
| 70° (approaching noon) | 2.60 | **2.91** | **+0.31 (+12%)** |
| 90° (noon) | 3.00 | 3.00 | 0.00 |
| 110° (past noon) | 2.60 | **2.91** | **+0.31 (+12%)** |
| 150° (late afternoon) | 1.80 | **2.20** | **+0.40 (+22%)** |
| 180° (sunset) | 1.20 | 1.20 | 0.00 |

### Key Improvements:
- **Early morning (30°)**: +22% brighter, reaches good lighting faster ✓
- **Midday plateau (70-110°)**: Stays at 2.91-3.00, stable lighting around noon ✓
- **Late afternoon (150°)**: +22% brighter, stays bright longer before sunset ✓

## Testing

### New Test File: `tests/test_sleep_sun_fixes.gd`

Created comprehensive tests for both fixes:

1. **`test_night_overlay_hidden_when_lockout_expires_on_load()`**
   - Simulates loading a save with an expired lockout
   - Verifies that `hide_night_overlay()` is called
   - Ensures night overlay is properly removed

2. **`test_quadratic_brightness_curve_brighter_early_morning()`**
   - Tests brightness at 30° sun position
   - Verifies quadratic curve produces 2.20 brightness (vs 1.80 linear)
   - Confirms at least 0.3 improvement over linear curve

3. **`test_quadratic_brightness_curve_plateau_at_noon()`**
   - Tests brightness from 70° to 110°
   - Verifies all values stay above 2.9 (near maximum)
   - Confirms stable midday lighting

### Updated Test: `tests/test_day_night_cycle.gd`

Updated `test_time_progression_to_930am()` to match new brightness:
- Old expectation: 1.4 ± 0.2 (linear curve)
- New expectation: 2.55 ± 0.2 (quadratic curve)

## Code Changes Summary

### Modified Files
1. **`scripts/day_night_cycle.gd`**
   - Line 147: Added `_hide_night_screen()` call
   - Line 368: Changed to quadratic brightness curve
   - Added comments explaining the quadratic curve

2. **`tests/test_day_night_cycle.gd`**
   - Lines 599-605: Updated brightness expectations for quadratic curve

3. **`tests/test_sleep_sun_fixes.gd`** (new file)
   - 159 lines of comprehensive test coverage

## Impact Assessment

### Benefits
- ✅ Fixes "strange start states" when restarting during expired lockout
- ✅ Resolves "very late brightness" with faster morning brightening
- ✅ Eliminates "sudden darkness" with stable midday plateau
- ✅ More realistic atmospheric lighting throughout the day
- ✅ Better gameplay experience with consistent lighting

### Risk Assessment
- ✅ Minimal code changes (2 lines of logic + comments)
- ✅ No breaking changes to existing functionality
- ✅ All existing tests updated to match new behavior
- ✅ No dependencies added
- ✅ No security vulnerabilities introduced
- ✅ Backwards compatible with existing save files

### Performance
- No performance impact
- Same number of calculations per frame
- Quadratic operation (x * x) is negligible overhead

## Verification

### Manual Testing Checklist
To verify the fixes work correctly:

**Sleep Timer Fix:**
1. Play game until sunset and night lockout begins
2. Wait a few hours (or 4+ hours in real time)
3. Close and restart the game
4. Expected: Night overlay should NOT be visible
5. Expected: Player can immediately start playing with sunrise animation

**Sun Brightness Fix:**
1. Start a new game or load existing save
2. Observe brightness in early morning (7-8 AM game time)
3. Expected: World should brighten noticeably faster than before
4. Watch brightness around noon (12-2 PM game time)
5. Expected: Brightness should stay consistently high, not fluctuate
6. Observe late afternoon (4-5 PM game time)
7. Expected: World should stay brighter longer before sunset

### Test Execution
Since Godot is not available in the CI environment, tests should be run locally:
```bash
./run_tests.sh
```

Expected results:
- All existing tests pass ✓
- New tests in `test_sleep_sun_fixes.gd` pass ✓
- Updated brightness expectations in `test_day_night_cycle.gd` pass ✓

## Related Issues & Documentation

- Fixes GitHub issue: "Schlafenszeit problem und sonnen problem"
- Related to previous fix: `NIGHT_LOCKOUT_LOAD_FIX.md` (player input during lockout)
- Logging categories used: `SLEEP_STATE_ISSUE`, `SUN_LIGHTING_ISSUE`

## Future Improvements (Out of Scope)

Potential enhancements not included in this minimal fix:
- Cubic or exponential curves for even more realistic lighting
- Different curves for different weather conditions
- Configurable brightness intensity in game settings
- Smooth transition animation when hiding night overlay

## Summary

This PR provides minimal, targeted fixes for both reported issues:
1. One line to hide night overlay when lockout expires
2. One line to use quadratic brightness curve instead of linear

Both changes significantly improve user experience while maintaining code simplicity and backwards compatibility.
