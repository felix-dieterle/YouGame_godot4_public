# Sun Position Display Feature

## Overview
This feature adds a real-time display of the sun's position in the game UI, showing the angle in a 0-180° range where:
- **0°** = Sunrise (sun at the horizon in the east)
- **90°** = Noon/Zenith (sun at its highest point)
- **180°** = Sunset (sun at the horizon in the west)

## Implementation Details

### UI Component
A new label `sun_position_label` was added to the `UIManager` class:
- **Location**: Bottom-right corner of the screen
- **Position**: Above the time speed controls (+/- buttons)
- **Color**: Yellow-orange tint (Color(1.0, 0.9, 0.5, 0.9))
- **Format**: "Sun: XXX°" or "Sun: Night" during nighttime

### Logic
The sun position is calculated in `DayNightCycle.get_sun_position_degrees()`:

```gdscript
func get_sun_position_degrees() -> float:
    # During night, return -1 to indicate sun is not visible
    if is_night and not is_animating_sunrise:
        return -1.0
    
    # Calculate time ratio (0.0 = sunrise, 0.5 = noon, 1.0 = sunset)
    var time_ratio: float = 0.0
    
    if is_animating_sunrise:
        # During sunrise animation, stay at 0° (sun at horizon)
        time_ratio = 0.0
    elif is_animating_sunset:
        # During sunset animation, stay at 180° (sun at horizon)
        time_ratio = 1.0
    else:
        # Normal day progression
        time_ratio = current_time / DAY_CYCLE_DURATION
    
    # Map 0.0-1.0 ratio to 0-180 degrees
    return time_ratio * 180.0
```

### Update Frequency
The sun position display is updated in the following scenarios:
1. **Normal day progression** - Every frame in `_update_lighting()`
2. **Sunrise animation** - During the sunrise transition in `_animate_sunrise()`
3. **Sunset animation** - During the sunset transition in `_animate_sunset()`
4. **Night mode** - When entering night mode in `_set_night_lighting()`

## Usage
The sun position is automatically displayed when the game runs. No player interaction is required.

### Examples
- At game start (7:00 AM / sunrise): **Sun: 0°**
- At mid-morning (9:30 AM): **Sun: 45°**
- At noon (12:00 PM): **Sun: 90°**
- At mid-afternoon (2:30 PM): **Sun: 135°**
- At sunset (5:00 PM): **Sun: 180°**
- During night: **Sun: Night**

## Technical Notes

### Coordinate System
The internal sun angle in the engine uses a different coordinate system:
- Internal: -60° (sunrise) to +60° (sunset)
- Display: 0° (sunrise) to 180° (sunset)

This mapping provides a more intuitive representation for players, matching typical astronomical conventions.

### Day Cycle Duration
- Total day cycle: 90 minutes (5400 seconds) in real-time
- Represents: 10 game hours (7:00 AM to 5:00 PM)
- Sun position updates continuously throughout this period

## Files Modified
1. `scripts/day_night_cycle.gd`:
   - Added `get_sun_position_degrees()` function
   - Added UI update calls in `_update_lighting()`, `_animate_sunrise()`, `_animate_sunset()`, and `_set_night_lighting()`

2. `scripts/ui_manager.gd`:
   - Added `sun_position_label` variable
   - Added label creation in `_ready()`
   - Added `update_sun_position()` function to update the label

## Future Enhancements
Potential improvements that could be added:
- Toggle visibility of the sun position display
- Show additional celestial information (moon phase, star visibility)
- Add sun path visualization on the minimap
- Display time until sunrise/sunset
