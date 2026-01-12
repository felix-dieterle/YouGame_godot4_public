# Day/Night Cycle - Quick Start Guide

## What You Get

A complete day/night cycle system that:
- Runs for 30 minutes before forcing the player to sleep
- Warns players 2 minutes and 1 minute before sunset
- Locks out gameplay for 4 hours when night falls
- Shows a beautiful sunrise animation when the lockout ends

## How to Test It

### Quick Test (30 seconds instead of 30 minutes)

1. Open the project in Godot
2. Open `scenes/main.tscn`
3. Select the `DayNightCycle` node
4. In the Inspector, check:
   - ✅ `debug_mode` (makes time run 60x faster)
   - ✅ `debug_skip_lockout` (skips the 4-hour wait)
5. Run the game (F5)
6. Watch the day cycle:
   - **0-28 seconds**: Normal day
   - **28 seconds**: "2 minutes until sunset!" warning
   - **29 seconds**: "1 minute until sunset NOW!" warning  
   - **30 seconds**: Sunset animation begins (lasts 1 second with debug mode)
   - **31 seconds**: Sunrise animation immediately starts (lockout skipped)
   - **32 seconds**: New day begins

### Full Test (Real Timings)

1. Disable both debug options
2. Run the game
3. Play for 28 minutes → First warning appears
4. Play for 29 minutes → Second warning appears
5. At 30 minutes → Sunset animation (1 minute)
6. At 31 minutes → Night overlay with 4-hour countdown
7. Close the game
8. Wait 4 hours (or change system time forward)
9. Reopen the game → Sunrise animation plays (1 minute)
10. New day begins!

## What Players Will See

### During the Day
- Sun moving across the sky
- Lighting changes (brighter at noon, dimmer at edges)
- Normal gameplay

### 2 Minutes Before Sunset
```
┌─────────────────────────────────────────┐
│  2 minutes until sunset!                │
│  Find a place to sleep.                 │
└─────────────────────────────────────────┘
```

### 1 Minute Before Sunset
```
┌─────────────────────────────────────────┐
│  1 minute until sunset!                 │
│  Find a place to sleep NOW!             │
└─────────────────────────────────────────┘
```

### During Sunset (1 minute)
- Sun descends below horizon
- Warm orange/red colors
- Light fades out
- Can still move during this time

### Night (4 hours)
```
┌─────────────────────────────────────────┐
│                                         │
│              Sleeping...                │
│                                         │
│        You cannot play for:             │
│             03:45:23                    │
│                                         │
└─────────────────────────────────────────┘
```
- Dark blue overlay covering screen
- Cannot move or interact
- Countdown timer shows remaining time
- State persists if game is closed/reopened

### Sunrise (1 minute)
- Sun rises from below horizon
- Warm colors fade to daylight
- Light gradually increases
- Cannot move during animation
- New day begins after animation

## Files to Know

- `scripts/day_night_cycle.gd` - Main system logic
- `scripts/ui_manager.gd` - Night overlay and warnings
- `scripts/player.gd` - Input control
- `scenes/main.tscn` - Scene with DayNightCycle node

## Customization

Edit constants in `scripts/day_night_cycle.gd`:

```gdscript
const DAY_CYCLE_DURATION: float = 30.0 * 60.0     # Change day length
const SLEEP_LOCKOUT_DURATION: float = 4.0 * 60.0 * 60.0  # Change sleep time
const WARNING_TIME_2MIN: float = 2.0 * 60.0       # Change first warning time
const WARNING_TIME_1MIN: float = 1.0 * 60.0       # Change second warning time
```

## Troubleshooting

**Sun not moving?**
- Check that DirectionalLight3D is in the scene
- Verify it's in the "DirectionalLight3D" group

**No warnings appearing?**
- Check that UIManager exists in the scene
- Verify show_message() method is available

**Player can still move at night?**
- Check that Player node exists and has set_input_enabled() method

**Night overlay not showing?**
- Check UIManager has show_night_overlay() method
- Verify night_overlay is created in _ready()

## That's It!

The system is fully automatic. Players will experience:
1. 30 minutes of gameplay
2. Two warnings before sunset
3. 1-minute sunset animation
4. 4-hour sleep period
5. 1-minute sunrise animation
6. Repeat!

Enjoy your day/night cycle! ��🌙
