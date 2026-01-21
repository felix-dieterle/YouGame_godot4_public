# Joystick Sensitivity and Size Adjustments

## Summary

This document describes the implementation of the requested joystick adjustments:

1. **Movement joystick left/right (horizontal) sensitivity reduced to 50%**
2. **Look joystick circle increased to 1.5x size**

## Implementation Details

### Constants Added

```gdscript
const LOOK_JOYSTICK_RADIUS: float = 120.0  # 1.5x larger than movement joystick
const LOOK_STICK_RADIUS: float = 45.0      # Proportionally larger stick (1.5x)
const MOVEMENT_HORIZONTAL_SENSITIVITY: float = 0.5  # Half as sensitive for left/right
```

### Changes to mobile_controls.gd

#### 1. Movement Joystick Horizontal Sensitivity (0.5x)

In the `_update_joystick()` function, the horizontal (X-axis) component of the joystick vector is now multiplied by 0.5:

```gdscript
# Before:
joystick_vector = normalized

# After:
joystick_vector = Vector2(normalized.x * MOVEMENT_HORIZONTAL_SENSITIVITY, normalized.y)
```

This makes left/right movement half as sensitive as forward/backward movement, helping players move in straighter lines without unintended lateral drift.

#### 2. Look Joystick Size Increase (1.5x)

The look joystick now uses `LOOK_JOYSTICK_RADIUS = 120.0` instead of the shared `JOYSTICK_RADIUS = 80.0`:

- **Base circle radius**: 120 pixels (was 80)
- **Stick radius**: 45 pixels (was 30)
- **Detection radius**: 180 pixels (was 120)

All look joystick code has been updated to use the new constants:
- `_create_look_joystick()` - joystick visual creation
- `_update_look_joystick()` - touch handling
- `_update_look_joystick_stick_position()` - visual feedback
- `_update_joystick_position()` - positioning
- `_input()` - touch detection

### Visual Impact

- **Movement joystick**: Unchanged in size (80 pixel radius), but horizontal movement requires more input
- **Look joystick**: Visibly larger (120 pixel radius), easier to use and see on screen
- **Touch detection**: Larger look joystick has proportionally larger detection area (180 vs 120 pixels)

## Testing

Created comprehensive test suite in `tests/test_joystick_sensitivity_and_size.gd`:

1. **Constants verification**: Ensures radii and sensitivity values are correct
2. **Horizontal sensitivity test**: Simulates touch input and verifies X-axis is reduced to 50% while Y-axis is unchanged
3. **Size verification**: Checks that look joystick base and stick are correctly sized

## Behavior Changes

### Movement Joystick
- **Before**: Pushing joystick fully right produces input vector `(1.0, 0.0)`
- **After**: Pushing joystick fully right produces input vector `(0.5, 0.0)`
- **Effect**: Requires 2x more joystick deflection for the same horizontal movement speed

### Look Joystick
- **Before**: 80 pixel radius, smaller on screen
- **After**: 120 pixel radius, 1.5x larger and more visible
- **Effect**: Easier to use, more space for precise camera control

## Backward Compatibility

All changes are additive and don't break existing functionality:
- Movement joystick vertical sensitivity unchanged
- Look joystick behavior unchanged (only size increased)
- All existing code paths preserved

## Files Modified

1. `scripts/mobile_controls.gd` - Core joystick implementation
2. `tests/test_joystick_sensitivity_and_size.gd` - New test suite
3. `tests/test_scene_joystick_sensitivity_and_size.tscn` - Test scene

## Author Notes

The implementation follows the principle of minimal changes:
- Only 3 new constants added
- Only the specific requested behaviors modified
- Existing tests continue to work
- No changes to player movement code or camera control logic
