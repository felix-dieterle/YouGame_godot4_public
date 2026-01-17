# Test Infrastructure Fixes - Summary

## Problem Statement
Tests existed for mobile controls and day/night cycle but were not running in CI/PR checks. Additionally, the tests did not reflect the real game behavior and thus didn't catch actual bugs.

## Changes Made

### 1. Added Missing Tests to Test Runner
**File:** `tests/run_tests.sh`

Added `test_scene_day_night_cycle.tscn` to the test runner so it now runs in CI/PR checks.

**Before:** Only 5 tests were running
**After:** 6 tests run, including day/night cycle tests

### 2. Fixed Mobile Controls Test (test_mobile_controls.gd)

#### Issue 1: Missing Parent z_index Configuration
The test wasn't matching the real game configuration from `main.tscn`.

**Fix:** Added `mobile_controls.z_index = 10` to match main.tscn

#### Issue 2: Incorrect z_index Check
The test was checking only the joystick's z_index (60), not considering the parent's contribution.

**Before:**
```gdscript
if look_base.z_index >= 60:
    print("PASS")
```

**After:**
```gdscript
var effective_z_index = mobile_controls.z_index + look_base.z_index
if effective_z_index > 100:
    print("PASS")
```

**Result:** Test will now FAIL (70 is not > 100), exposing the bug where joystick is not visible on mobile because it renders below UI elements (z_index 100+)

### 3. Fixed Day/Night Cycle Tests (test_day_night_cycle.gd)

#### Issue: Incorrect Time Mapping
Tests were using wrong assumptions about the in-game time cycle.

**Wrong Assumption:** Day cycle represents 6:00 AM to 5:00 PM (11 hours)
**Correct:** Day cycle represents 7:00 AM to 5:00 PM (10 hours, after sunrise animation completes)

**Changes:**
- `EIGHT_AM_RATIO`: Changed from `2.0 / 11.0` to `1.0 / 10.0`
- `NINE_THIRTY_AM_RATIO`: Changed from `3.5 / 11.0` to `2.5 / 10.0`

#### Added New Test: `test_time_display_matches_sun_position()`
This test specifically checks if the displayed time matches the sun position and will FAIL to expose the time display bug.

**What it tests:**
- At sun zenith (time_ratio=0.5), display should show 12:00 (noon)
- Current buggy formula shows 11:30 instead
- At 9:30 AM, verifies correct time_ratio (0.25) is used

## Root Causes Identified

### Bug 1: Joystick Not Visible on Mobile
**Location:** `scenes/main.tscn` and `scripts/mobile_controls.gd`

**Root Cause:** 
- MobileControls parent has `z_index = 10` (from main.tscn)
- Joystick children have `z_index = 60`
- Effective z_index = 10 + 60 = **70**
- Other UI elements (version label, debug overlay, etc.) have z_index = **100+**
- Joystick renders BELOW these elements → not visible on mobile

**Fix Required:** Increase MobileControls parent z_index or joystick child z_index so effective > 100

### Bug 2: Time Display Doesn't Match Sun Position
**Location:** `scripts/ui_manager.gd` lines 46-47 and 303

**Root Cause:**
```gdscript
const SUNRISE_TIME_MINUTES: int = 360  # 6:00 AM - WRONG!
const DAY_DURATION_HOURS: float = 11.0  # 11 hours - WRONG!

// In update_game_time():
var total_minutes = int(time_ratio * DAY_DURATION_HOURS * 60.0) + SUNRISE_TIME_MINUTES
```

The sunrise animation represents 6:00-7:00 AM (60 seconds real time). After it completes, `current_time = 0` should represent 7:00 AM, not 6:00 AM.

**Current Behavior:**
- At time_ratio = 0.5 (sun at zenith): Display shows **11:30 AM**
- At time_ratio = 0.318 (when display shows 9:30): Sun position is for **11:30 AM equivalent**

**Fix Required:**
```gdscript
const SUNRISE_TIME_MINUTES: int = 420  # 7:00 AM (after sunrise completes)
const DAY_DURATION_HOURS: float = 10.0  # 10 hours (7 AM to 5 PM)

var total_minutes = int(time_ratio * 10.0 * 60.0) + 420
```

**Effect of Bug:**
- ~1 hour offset between displayed time and sun position
- At 9:30 AM displayed time, sun is in position for later in day
- This makes the game look "too dark" at times when it should be bright

### Bug 3: Sky Not Bright Blue
**Related to:** Bug #2 (Time display offset)

When the display shows 9:30 AM but sun is in wrong position due to time offset, the sky appears gloomy instead of bright blue. The PhysicalSkyMaterial settings are correct (rayleigh=3.0, mie=0.003, turbidity=8.0), but they're being evaluated at the wrong time_ratio.

## Test Results Expected

When PR tests run, the following tests will **FAIL** (as intended to expose bugs):

1. ✗ **test_mobile_controls** → `test_look_joystick_properties()`
   - Fails on: "effective z_index > 100"
   - Actual: 70
   - Exposes joystick visibility bug

2. ✗ **test_day_night_cycle** → `test_time_display_matches_sun_position()`
   - Fails on: "At sun zenith, display should show 12:00"
   - Actual: Shows 11:30
   - Exposes time display bug

These failures are EXPECTED and DESIRED - they prove the tests now correctly catch the real bugs.

## How to Fix the Bugs

### Fix Joystick Visibility
**Option 1:** Increase MobileControls parent z_index in `scenes/main.tscn`:
```
z_index = 101  # Above UI elements
```

**Option 2:** Increase joystick z_index in `scripts/mobile_controls.gd`:
```gdscript
joystick_base.z_index = 100  # Then effective = 10 + 100 = 110
look_joystick_base.z_index = 100
```

### Fix Time Display
Edit `scripts/ui_manager.gd`:

**Lines 46-47:**
```gdscript
const SUNRISE_TIME_MINUTES: int = 420  # 7:00 AM (after sunrise completes)
const DAY_DURATION_HOURS: float = 10.0  # 10 hours (7 AM to 5 PM)
```

**Line 303:**
```gdscript
var total_minutes = int(time_ratio * 10.0 * 60.0) + 420
```

## Verification

After applying fixes, the tests should **PASS**:
- Mobile controls test will pass when effective z_index > 100
- Day/night test will pass when time display shows 12:00 at sun zenith
- Game will show correct times matching sun positions
- Sky will be bright blue at 9:30 AM because sun will be in correct position

## Notes

The tests now accurately reflect the real game behavior and will continue to catch these bugs if they're reintroduced. The tests are also run automatically on every PR to the main branch via GitHub Actions.
