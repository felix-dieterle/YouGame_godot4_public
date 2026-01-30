# Environment Systems

Dynamic environmental effects and atmospheric systems.

## Files

### Day/Night Cycle (`day_night_cycle.gd`)
- Time of day progression
- Dynamic lighting transitions
- Sun/moon positioning
- Time multiplier: 2.0x (configurable)
- Sky color transitions

### Weather System (`weather_system.gd`)
- Weather state management
- Weather transitions (CLEAR, etc.)
- Integrated with day/night cycle
- Visual weather effects

## Usage

```gdscript
# In main scene
var day_night = DayNightCycle.new()
add_child(day_night)

var weather = WeatherSystem.new()
add_child(weather)
```

## Integration

- Both systems update lighting and atmosphere
- Weather effects respond to time of day
- Impacts player visibility and gameplay experience
