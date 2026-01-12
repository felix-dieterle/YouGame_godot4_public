# Day/Night Cycle System

## Overview
The day/night cycle system adds a time-based gameplay mechanic where players experience a 30-minute day cycle followed by a 4-hour real-time sleep period.

## Features

### Day Cycle (30 minutes)
- Full day lasts 30 minutes of real-time gameplay
- Sun moves across the sky, changing lighting and atmosphere
- Dynamic lighting adjusts throughout the day
- Sun is brightest at noon, dimmer at sunrise/sunset

### Sleep Warnings
- **2 minutes before sunset**: First warning message appears
- **1 minute before sunset**: Final urgent warning appears
- Messages remind players to find a place to sleep

### Sunset Animation (1 minute)
- Smooth transition from day to night
- Sun descends below the horizon
- Light fades out gradually
- Warm sunset colors appear

### Night/Sleep Period (4 hours real-time)
- After sunset, the game becomes unplayable
- Dark overlay appears with "Sleeping..." message
- Countdown timer shows remaining sleep time (HH:MM:SS)
- Player input is disabled during this period
- State is saved so the lockout persists across game restarts

### Sunrise Animation (1 minute)
- When sleep period ends and player starts the game, sunrise animation plays
- Sun rises from below the horizon
- Light gradually fades in
- New day begins after animation completes

## Implementation Details

### Main Components

1. **DayNightCycle** (`scripts/day_night_cycle.gd`)
   - Manages time progression
   - Controls sun rotation and lighting
   - Handles save/load of sleep state
   - Triggers warnings and animations

2. **UIManager** (updated)
   - Shows warning messages
   - Displays night overlay with countdown
   - Manages sleep UI

3. **Player** (updated)
   - Can enable/disable input based on day/night state
   - Controlled by DayNightCycle system

### Save System
The system uses Godot's `ConfigFile` to save:
- Whether player is currently in sleep lockout
- Unix timestamp when lockout ends
- Current time in the day cycle

Save file location: `user://day_night_save.cfg`

### Debug Mode
For testing purposes, the DayNightCycle node has two debug options:

- **debug_mode**: When enabled, time runs 60x faster (30-minute day becomes 30 seconds)
- **debug_skip_lockout**: When enabled, bypasses the 4-hour sleep lockout

To enable debug mode:
1. Select the DayNightCycle node in main.tscn
2. In the Inspector, check the debug_mode and/or debug_skip_lockout options

## Configuration

All timing constants are defined in `scripts/day_night_cycle.gd`:

```gdscript
const DAY_CYCLE_DURATION: float = 30.0 * 60.0  # 30 minutes
const SUNRISE_DURATION: float = 60.0           # 1 minute
const SUNSET_DURATION: float = 60.0            # 1 minute
const SLEEP_LOCKOUT_DURATION: float = 4.0 * 60.0 * 60.0  # 4 hours
const WARNING_TIME_2MIN: float = 2.0 * 60.0    # 2 minutes before sunset
const WARNING_TIME_1MIN: float = 1.0 * 60.0    # 1 minute before sunset
```

## Technical Details

### Sun Position Calculation
- Sun angle is calculated based on time ratio (current_time / DAY_CYCLE_DURATION)
- Sun moves from east (-90°) to west (90°) over the day
- Rotation is applied to DirectionalLight3D's X-axis

### Light Intensity
- Calculated using a curve: brightest at noon, dimmer at edges
- Formula: `1.0 - abs(time_ratio - 0.5) * 2.0`
- Energy ranges from 0.6 (sunrise/sunset) to 1.5 (noon)

### Ambient Colors
- Warmer colors (more orange/red) at sunrise and sunset
- Neutral white at noon
- Very dark blue during night

## Integration with Main Scene

The DayNightCycle is added to `scenes/main.tscn`:
- Requires DirectionalLight3D in scene (with group "DirectionalLight3D")
- Requires WorldEnvironment in scene (with group "WorldEnvironment")
- Requires UIManager node for displaying messages
- Requires Player node for controlling input

## Future Enhancements

Possible improvements:
- Add stars/moon during night
- Allow players to build shelters to skip the sleep requirement
- Add weather system integration (storms at night, etc.)
- Add time-of-day dependent gameplay mechanics
- Add quick sleep option when player is in safe location
