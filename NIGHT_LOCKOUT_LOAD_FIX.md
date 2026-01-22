# Fix: Player Input During Night Lockout Load

## Problem Statement (German)
**Title:** Problem laden nach Neustart während schlafenszeit  
**Translation:** Problem loading after restart during sleep time

## Issue Description
When the game was restarted during an active night lockout period (Schlafenszeit), there was a race condition where the player's input would be briefly enabled before being properly disabled by the DayNightCycle system.

### Root Cause
The issue occurred due to the scene tree initialization order:

1. `SaveGameManager` (autoload) loads the save file in `_ready()`
2. `Player._ready()` is called (scene tree order)
   - Player loads saved state with `input_enabled = true` (default value)
   - Player becomes controllable
3. `DayNightCycle._ready()` is called later (scene tree order)
   - Checks lockout state
   - Calls `_disable_player_input()` to disable player control

This created a timing window where:
- Player state was loaded
- Input was enabled by default
- A few frames could pass before DayNightCycle disabled input
- Player could potentially move or interact during lockout

### Scene Tree Order
From `scenes/main.tscn`:
- Line 54: `Player` node created
- Line 64: `DayNightCycle` node created

Since nodes are initialized in tree order, Player's `_ready()` completes before DayNightCycle's `_ready()` is called.

## Solution

### Implementation
Added a check in `Player._load_saved_state()` to immediately disable input if loading during an active lockout:

```gdscript
# Check if we're loading during night lockout and disable input if so
var day_night_data = SaveGameManager.get_day_night_data()
if day_night_data.get("is_locked_out", false):
    var current_unix_time = Time.get_unix_time_from_system()
    var lockout_end_time = day_night_data.get("lockout_end_time", 0.0)
    # Only disable input if lockout hasn't expired yet
    if current_unix_time < lockout_end_time:
        input_enabled = false
        print("Player: Input disabled - loading during night lockout (%.1f seconds remaining)" % (lockout_end_time - current_unix_time))
```

### Why This Works
1. **SaveGameManager is autoload**: It loads before the main scene, so save data is available
2. **Player can query lockout state**: SaveGameManager provides `get_day_night_data()` method
3. **Immediate disabling**: Player disables input in `_load_saved_state()` before any physics processing
4. **Safe redundancy**: DayNightCycle still disables input later, providing double protection
5. **Proper re-enabling**: DayNightCycle still manages enabling input when sunrise completes

### Edge Cases Handled
- **Lockout expired**: Checks if `current_unix_time < lockout_end_time` before disabling
- **No lockout**: Only disables if `is_locked_out == true`
- **No save file**: Function returns early if no save exists
- **System time changes**: Uses the same time comparison logic as DayNightCycle

## Code Changes

### Modified Files
1. **scripts/player.gd**
   - Lines 835-843: Added lockout check in `_load_saved_state()`
   - Queries SaveGameManager for day/night lockout state
   - Disables input if lockout is active and not expired
   - Logs the action for debugging

### New Files
1. **tests/test_player_lockout_load.gd**
   - Comprehensive test suite for lockout loading scenarios
   - Tests 3 scenarios:
     1. Loading during active lockout (input disabled)
     2. Loading after lockout expires (input enabled)
     3. Loading with no lockout (input enabled)

## Testing

### Test Coverage
Created `test_player_lockout_load.gd` with three comprehensive tests:

#### Test 1: Input Disabled During Active Lockout
```gdscript
test_player_input_disabled_when_loading_during_lockout()
```
- Creates save with lockout_end_time 60 seconds in future
- Loads save and creates player
- Verifies `input_enabled == false`
- Verifies player position restored correctly

#### Test 2: Input Enabled After Lockout Expires
```gdscript
test_player_input_enabled_when_loading_after_lockout_expires()
```
- Creates save with lockout_end_time 100 seconds in past
- Loads save and creates player
- Verifies `input_enabled == true` (lockout expired)
- Verifies player position restored correctly

#### Test 3: Input Enabled With No Lockout
```gdscript
test_player_input_enabled_when_no_lockout()
```
- Creates save with `is_locked_out == false`
- Loads save and creates player
- Verifies `input_enabled == true`
- Verifies player position restored correctly

### Manual Testing
To manually test the fix:

1. Play the game until sunset begins (night lockout starts)
2. Wait for the night screen to appear
3. Close and restart the game
4. Verify:
   - Night overlay is displayed
   - Countdown timer shows remaining sleep time
   - Player cannot move or interact
   - MobileControls are visible but non-functional

## Impact Assessment

### No Regressions
- ✅ Normal gameplay unchanged (no lockout scenarios)
- ✅ DayNightCycle still manages runtime input enable/disable
- ✅ Sunrise animation properly re-enables input
- ✅ Sunset animation properly disables input
- ✅ Only affects initial load during active lockout

### Performance
- Minimal impact: Single dictionary lookup and time comparison during load
- No runtime performance impact
- No additional memory usage

### Compatibility
- ✅ Compatible with existing save files
- ✅ Works with old and new save formats
- ✅ No changes to save/load data structure
- ✅ Backwards compatible with saves created before fix

## Security Review
- ✅ No security vulnerabilities introduced
- ✅ No new dependencies
- ✅ No sensitive data exposure
- ✅ CodeQL found no issues (GDScript not analyzed)

## Debug Logging
Added informative log message when input is disabled during lockout load:
```
Player: Input disabled - loading during night lockout (X.X seconds remaining)
```

This helps with:
- Debugging lockout loading issues
- Verifying the fix is working
- Understanding player state during development

## Related Systems

### SaveGameManager
- Provides `get_day_night_data()` method
- Already loads save file in `_ready()` before main scene
- No changes required

### DayNightCycle
- Still manages runtime lockout state
- Still disables/enables input during sunset/sunrise
- Provides redundant safety by also disabling input in `_ready()`
- No changes required

### MobileControls
- Unaffected by the fix
- Still created and visible during lockout
- Input disabled at player level, not UI level
- No changes required

## Summary
This fix ensures that when a game is loaded during an active night lockout period, the player's input is immediately disabled, preventing any brief window where the player could move or interact. The solution is minimal, safe, well-tested, and introduces no regressions to existing functionality.

The fix addresses the race condition between Player and DayNightCycle initialization by having Player directly check the lockout state from SaveGameManager during load, rather than waiting for DayNightCycle to disable input later.
