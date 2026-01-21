# Look Joystick Inversion Fix

## Date
2026-01-21

## Problem Statement (German)
> der look button reagiert sowohl wertikal als auch horizontal spiegelverkehrt

**Translation:**
The look button reacts both vertically and horizontally mirrored/inverted.

## Issue Description
The look joystick (camera control) was responding in the opposite direction both horizontally and vertically:
- Pushing the joystick right caused the camera to rotate left (or vice versa)
- Pushing the joystick up caused the camera to tilt down (or vice versa)

This made camera control unintuitive and difficult to use.

## Root Cause
The joystick input coordinates were being directly mapped to camera rotation angles without proper sign correction. The screen coordinate system (where Y increases downward) and the expected camera behavior required negation of both axes to achieve intuitive control.

## Solution
Negated both X and Y axes when converting between joystick position and camera angles in two functions:

### 1. Input Processing (`_update_look_joystick()`)
**File:** `scripts/mobile_controls.gd`, lines 367-369

**Before:**
```gdscript
look_target_yaw = normalized.x * deg_to_rad(max_yaw_deg)
look_target_pitch = normalized.y * deg_to_rad(max_pitch_deg)
```

**After:**
```gdscript
# Negate both axes to fix inverted behavior
look_target_yaw = -normalized.x * deg_to_rad(max_yaw_deg)
look_target_pitch = -normalized.y * deg_to_rad(max_pitch_deg)
```

### 2. Visual Feedback (`_update_look_joystick_stick_position()`)
**File:** `scripts/mobile_controls.gd`, lines 164-166

**Before:**
```gdscript
var normalized_x = yaw / max_yaw_rad if max_yaw_rad > 0 else 0.0
var normalized_y = pitch / max_pitch_rad if max_pitch_rad > 0 else 0.0
```

**After:**
```gdscript
# Negate both axes to match the fix in _update_look_joystick (visual consistency)
var normalized_x = -yaw / max_yaw_rad if max_yaw_rad > 0 else 0.0
var normalized_y = -pitch / max_pitch_rad if max_pitch_rad > 0 else 0.0
```

## Expected Behavior After Fix
- **Push joystick right** → Camera rotates right (pans to the right)
- **Push joystick left** → Camera rotates left (pans to the left)
- **Push joystick up** → Camera tilts up (looks upward)
- **Push joystick down** → Camera tilts down (looks downward)

This matches the intuitive control scheme used in most 3D games.

## Testing Required
**IMPORTANT:** Manual testing is required to verify this fix:

1. Test on a mobile device or touch-enabled device
2. Verify that camera controls now respond intuitively:
   - Right joystick movement → camera looks right
   - Up joystick movement → camera looks up
3. Check both first-person and third-person camera modes
4. Verify the joystick stick visual position matches the camera direction

### Test Expectations
The existing automated test `test_look_joystick_absolute_position.gd` was written to expect the previous (buggy) behavior. After manual verification that this fix is correct, the test expectations should be updated:

- Line 129: Change `expected_yaw = deg_to_rad(80.0)` to `deg_to_rad(-80.0)`
- Lines 190-191: Change expected angles from positive to negative values

## Technical Notes
- The fix maintains visual consistency between joystick input and camera feedback
- Both functions were updated to ensure the joystick stick position correctly reflects the camera direction
- The changes are minimal and surgical, affecting only the coordinate system conversion
- No changes to game logic, camera setup, or other systems were required

## Files Modified
1. `scripts/mobile_controls.gd` - Fixed joystick-to-camera angle conversion (2 locations)

## Files to Update After Verification
1. `tests/test_look_joystick_absolute_position.gd` - Update test expectations to match corrected behavior
