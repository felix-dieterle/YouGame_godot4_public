# Day/Night Cycle - Visual and Functional Guide

## What Has Been Implemented

This implementation adds a complete day/night cycle system to YouGame with the following features:

### 1. Day Cycle (30 minutes)
- **Duration**: 30 minutes of real-time gameplay
- **Sun Movement**: The DirectionalLight3D rotates across the sky simulating the sun's path
- **Lighting Changes**:
  - Morning: Warm orange/yellow tones, moderate brightness
  - Noon: Bright white light at peak intensity
  - Evening: Warm orange/red tones, fading brightness
  - Night: Very dark, minimal ambient light

### 2. Sleep Warning System
Players receive two warnings before sunset:

#### First Warning (2 minutes before sunset)
- **Message**: "2 minutes until sunset! Find a place to sleep."
- **Duration**: Displays for 5 seconds
- **Timing**: When 28 minutes have elapsed in the day cycle

#### Second Warning (1 minute before sunset)
- **Message**: "1 minute until sunset! Find a place to sleep NOW!"
- **Duration**: Displays for 5 seconds
- **Timing**: When 29 minutes have elapsed in the day cycle

### 3. Sunset Animation (1 minute)
When the 30-minute day ends:
- Sun gradually descends below the horizon
- Lighting smoothly fades from warm sunset colors to darkness
- Transition takes exactly 1 minute
- Player can still move during this animation

### 4. Night/Sleep Period (4 hours real-time)
After sunset animation completes:
- **Dark Overlay**: A semi-transparent dark blue overlay covers the entire screen
- **Sleep Message**: Center of screen displays "Sleeping..."
- **Countdown Timer**: Shows remaining sleep time in format HH:MM:SS
- **Player Input**: Completely disabled - cannot move or interact
- **Persistent**: If player closes and reopens the game during the 4-hour period, they remain locked out
- **Save System**: Sleep state is saved to `user://day_night_save.cfg`

### 5. Sunrise Animation (1 minute)
When the 4-hour sleep period expires and player starts the game:
- Sun gradually rises from below the horizon
- Lighting smoothly transitions from darkness to morning light
- Warm sunrise colors appear
- Takes exactly 1 minute
- Player input remains disabled during animation
- After animation completes, a new 30-minute day begins

## User Experience Flow

### Normal Gameplay Day
1. Game starts with sun in the sky
2. Player explores for up to 30 minutes
3. At 28 minutes: First warning appears
4. At 29 minutes: Second warning appears
5. At 30 minutes: Sunset animation begins (1 minute)
6. At 31 minutes: Night overlay appears, sleep timer starts at 04:00:00
7. Player must wait 4 hours real-time or use debug mode

### Returning After Sleep
1. Player opens game after 4+ hours have passed
2. Sunrise animation automatically plays (1 minute)
3. New day begins with sun in morning position
4. Player can move and play for another 30 minutes

### Mid-Sleep Return
1. Player opens game before 4 hours have passed
2. Night overlay is immediately visible
3. Countdown shows remaining time (e.g., "02:34:18")
4. Player cannot do anything until time expires
5. Game remains locked until countdown reaches 00:00:00

## Debug Features for Testing

The system includes two debug options visible in the Godot Inspector when selecting the DayNightCycle node:

### debug_mode
- **Effect**: Accelerates time by 60x
- **Result**: 30-minute day becomes 30 seconds, 4-hour lockout becomes 4 minutes
- **Use Case**: Testing the full cycle quickly

### debug_skip_lockout
- **Effect**: Bypasses the 4-hour sleep requirement
- **Result**: Immediately triggers sunrise after sunset
- **Use Case**: Testing day/sunset/sunrise without waiting

## Technical Implementation

### Modified Files
1. **scripts/day_night_cycle.gd** (NEW)
   - Core day/night cycle logic
   - Time tracking and state management
   - Save/load functionality
   - Lighting and animation control

2. **scripts/ui_manager.gd** (UPDATED)
   - Added night overlay UI
   - Added countdown timer
   - Added night overlay show/hide methods

3. **scripts/player.gd** (UPDATED)
   - Added input_enabled flag
   - Added set_input_enabled() method
   - Input processing checks enabled state

4. **scenes/main.tscn** (UPDATED)
   - Added DayNightCycle node
   - Added DirectionalLight3D to group for discovery
   - Linked all required systems

### New Files
1. **tests/test_day_night_cycle.gd** - Automated tests
2. **tests/test_scene_day_night_cycle.tscn** - Test scene
3. **DAY_NIGHT_CYCLE.md** - Complete documentation

## Configuration

All timing can be adjusted in `scripts/day_night_cycle.gd`:

```gdscript
const DAY_CYCLE_DURATION: float = 30.0 * 60.0  # 30 minutes (1800 seconds)
const SUNRISE_DURATION: float = 60.0           # 1 minute (60 seconds)
const SUNSET_DURATION: float = 60.0            # 1 minute (60 seconds)
const SLEEP_LOCKOUT_DURATION: float = 4.0 * 60.0 * 60.0  # 4 hours (14400 seconds)
const WARNING_TIME_2MIN: float = 2.0 * 60.0    # 2 minutes (120 seconds)
const WARNING_TIME_1MIN: float = 1.0 * 60.0    # 1 minute (60 seconds)
```

## Testing the Feature

### Quick Test with Debug Mode
1. Open Godot Editor
2. Select DayNightCycle node in main.tscn
3. Enable both `debug_mode` and `debug_skip_lockout` in Inspector
4. Run the game
5. Observe:
   - Day cycle completes in 30 seconds
   - Warnings appear at 28s and 29s
   - Sunset animation at 30s (1 second due to 60x speed)
   - Sunrise immediately after (skips lockout)
   - New day begins

### Full Test without Debug Mode
1. Disable debug options
2. Run the game
3. Wait 28 minutes for first warning
4. Wait 29 minutes for second warning
5. Wait 30 minutes for sunset
6. Watch sunset animation (1 minute)
7. See sleep overlay with 04:00:00 countdown
8. Close game and wait 4 hours
9. Reopen game to see sunrise animation

## Requirements Checklist

✅ Day/night cycle with 30-minute period  
✅ 2-minute warning before sunset  
✅ 1-minute warning before sunset  
✅ Game becomes unplayable for 4 hours after sunset  
✅ Sunrise animation on next game start (1 minute)  
✅ Persistent sleep state across game sessions  
✅ Visual feedback with overlays and messages  
✅ Player input disabled during night  
✅ Countdown timer showing remaining sleep time  

All requirements from the problem statement have been fully implemented!
