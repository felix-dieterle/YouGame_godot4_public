# Countdown Display Bug Fix

## Problem Statement
No countdown shown after leaving the Android game when sleep time in game has already begun and reopening the game.

## Root Cause
Race condition during initialization when the game is reopened during the sleep lockout period.

### Technical Details
When a player reopens the game during the 4-hour sleep lockout period:

1. `DayNightCycle._ready()` is called
2. It loads the saved state showing `is_locked_out = true`
3. It tries to show the night screen by calling `_show_night_screen()`
4. `_show_night_screen()` calls `ui_manager.show_night_overlay(lockout_end_time)`
5. **Bug**: If `UIManager._ready()` hasn't finished creating all UI elements (including `countdown_timer`), the timer might not exist yet when `show_night_overlay()` is called

This is a classic race condition where the order of `_ready()` execution between sibling nodes is not guaranteed.

## Solution
Defer the call to `_show_night_screen()` to ensure `UIManager` is fully initialized before attempting to show the night overlay.

### Code Change
**File**: `scripts/day_night_cycle.gd`
**Line**: 123

**Before**:
```gdscript
else:
    # Still in lockout, show night screen
    is_night = true
    _show_night_screen()
    _set_night_lighting()
```

**After**:
```gdscript
else:
    # Still in lockout, show night screen
    is_night = true
    # Defer the call to ensure UI Manager is fully initialized
    call_deferred("_show_night_screen")
    _set_night_lighting()
```

### Why This Works
- `call_deferred()` queues the function call to execute after the current frame's processing is complete
- This ensures all `_ready()` functions have finished executing
- By the time `_show_night_screen()` is called, `UIManager` has created all its UI elements including `countdown_timer`
- The countdown timer can now be properly started and will display correctly

## Test Coverage
Added a new test `test_countdown_on_reopen_during_lockout()` in `tests/test_day_night_cycle.gd` that:

1. Creates a game state with active lockout
2. Saves the state
3. Simulates reopening the game (creates new scene instances)
4. Verifies that:
   - Lockout state is properly loaded
   - Night overlay is visible
   - Countdown timer is running
   - Countdown text is displayed

This test will now run as part of PR checks to prevent regression of this bug.

## PR Check Integration
Updated `tests/run_tests.sh` to include the day/night cycle tests in the test suite:

```bash
tests=(
    "res://tests/test_scene_chunk.tscn|Chunk Tests"
    "res://tests/test_scene_narrative_markers.tscn|Narrative Markers Tests"
    "res://tests/test_scene_clusters.tscn|Clusters Tests"
    "res://tests/test_scene_visual_example.tscn|Visual Example Tests"
    "res://tests/test_scene_mobile_controls.tscn|Mobile Controls Tests"
    "res://tests/test_scene_day_night_cycle.tscn|Day Night Cycle Tests"  # NEW
)
```

The GitHub Actions workflow (`.github/workflows/build.yml`) already runs `tests/run_tests.sh`, so this test will automatically run on all PRs.

## Impact
- **Before**: Countdown not shown when reopening game during sleep lockout, making it unclear how long the player needs to wait
- **After**: Countdown properly displays, showing the player exactly how much time remains until they can play again
- **No Breaking Changes**: The fix is minimal and only affects the initialization order, not the runtime behavior

## Related Files
- `scripts/day_night_cycle.gd` - Fixed initialization race condition
- `tests/test_day_night_cycle.gd` - Added test for countdown display
- `tests/run_tests.sh` - Added day/night cycle tests to PR checks
- `.github/workflows/build.yml` - Already configured to run test suite

## Verification
To verify the fix works:

1. Start the game and play until sunset (night begins)
2. Close the game during the 4-hour lockout period
3. Reopen the game
4. **Expected**: Night overlay appears with countdown timer showing remaining time
5. **Previously**: Night overlay might appear but countdown was not shown

## Notes
- The fix uses Godot's built-in `call_deferred()` mechanism which is the recommended approach for handling initialization order dependencies
- This is a common pattern in Godot for ensuring nodes are fully initialized before accessing their properties
- The fix is minimal (1 line change) and low-risk
