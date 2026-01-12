# Sky Weather Implementation

## Problem Statement (German)
> der Himmel soll sich passend zum Wetter mit ändern, dh Wolken aufziehen lassen wenn es bald beginnt zu regnen usw.

**Translation**: The sky should change according to the weather, i.e., clouds should gather when it's about to rain, etc.

## Solution: Dynamic Sky Based on Weather

### Overview
The weather system now controls not just fog and rain, but also the appearance of the sky. As weather changes, the sky transitions smoothly between clear blue skies and dark, cloudy storm conditions.

### Implementation Details

#### 1. Updated Environment Setup (`scenes/main.tscn`)

Changed from a simple background color to a physically-based sky:

**Before:**
```gdscript
background_mode = 1  # Single color
background_color = Color(0.53, 0.81, 0.92, 1)
ambient_light_source = 2  # Color
```

**After:**
```gdscript
background_mode = 2  # Sky
sky = SubResource("Sky_1")  # PhysicalSkyMaterial
ambient_light_source = 3  # Sky
ambient_light_sky_contribution = 1.0
```

#### 2. PhysicalSkyMaterial Configuration

Added a new PhysicalSkyMaterial with these initial parameters:
- **Rayleigh Coefficient**: 2.0 (controls blue sky color)
- **Rayleigh Color**: Blue tint
- **Mie Coefficient**: 0.005 (controls atmospheric haze/clouds)
- **Turbidity**: 10.0 (atmospheric thickness)
- **Sun Disk Scale**: 1.0
- **Ground Color**: Brown/earth tone

These parameters are dynamically adjusted by the weather system.

#### 3. Enhanced Weather System (`scripts/weather_system.gd`)

##### New Sky Parameters for Each Weather State

| Weather State | Turbidity | Mie Coefficient | Rayleigh Coefficient | Visual Effect |
|---------------|-----------|-----------------|---------------------|---------------|
| **CLEAR** | 10.0 | 0.005 | 2.0 | Bright, clear blue sky |
| **LIGHT_FOG** | 15.0 | 0.01 | 1.5 | Slightly hazy, less vibrant |
| **HEAVY_FOG** | 18.0 | 0.02 | 1.0 | Dense atmospheric haze |
| **LIGHT_RAIN** | 20.0 | 0.015 | 1.2 | Cloudy, greyish sky |
| **HEAVY_RAIN** | 30.0 | 0.025 | 0.8 | Dark, stormy sky |

##### Sky Parameter Effects

1. **Turbidity** (10.0 - 30.0):
   - Higher values = more atmospheric scattering
   - Creates a cloudier, hazier appearance
   - 30.0 gives a very stormy, overcast look

2. **Mie Coefficient** (0.005 - 0.025):
   - Controls the amount of haze and cloud-like scattering
   - Higher values = more visible clouds/haze
   - Simulates particle scattering in the atmosphere

3. **Rayleigh Coefficient** (0.8 - 2.0):
   - Controls the blue color intensity of the sky
   - Higher values = more vibrant blue
   - Lower values = darker, greyer sky
   - 0.8 creates the dark, stormy look for heavy rain

##### Smooth Transitions

The sky parameters interpolate smoothly during weather transitions (30 seconds by default):

```gdscript
if sky_material:
    var turbidity = lerp(current_params.turbidity, target_params.turbidity, transition_progress)
    var mie_coefficient = lerp(current_params.mie_coefficient, target_params.mie_coefficient, transition_progress)
    var rayleigh_coefficient = lerp(current_params.rayleigh_coefficient, target_params.rayleigh_coefficient, transition_progress)
    
    sky_material.turbidity = turbidity
    sky_material.mie_coefficient = mie_coefficient
    sky_material.rayleigh_coefficient = rayleigh_coefficient
```

### Weather Transition Timeline

When transitioning from **CLEAR** to **HEAVY_RAIN**:

1. **T = 0s**: Clear blue sky (turbidity: 10.0, mie: 0.005, rayleigh: 2.0)
2. **T = 10s**: Sky starts darkening (turbidity: ~16.7, mie: ~0.012, rayleigh: ~1.6)
3. **T = 20s**: Clouds gathering (turbidity: ~23.3, mie: ~0.018, rayleigh: ~1.2)
4. **T = 30s**: Full storm (turbidity: 30.0, mie: 0.025, rayleigh: 0.8)

The visual effect is that clouds gradually appear and darken as the weather worsens.

### Visual Effects Summary

- **Clear Weather**: Bright blue sky, minimal haze
- **Light Fog**: Slightly dulled sky, some atmospheric haze
- **Heavy Fog**: Murky, hazy sky with low visibility
- **Light Rain**: Grey, overcast sky with moderate clouds
- **Heavy Rain**: Dark, stormy sky with heavy cloud cover

### Files Modified

1. **`scenes/main.tscn`**:
   - Added PhysicalSkyMaterial resource
   - Added Sky resource
   - Changed Environment to use sky-based background
   - Updated ambient light to use sky

2. **`scripts/weather_system.gd`**:
   - Added `sky_material` variable
   - Updated `_setup_environment()` to get sky material reference
   - Modified `_apply_weather_transition()` to interpolate sky parameters
   - Extended `_get_weather_params()` to include sky parameters for each weather state

### How to Test

1. **Run the game** in Godot
2. **Observe the sky**: It should start with a clear blue appearance
3. **Wait for weather changes**: The system changes weather every 2-5 minutes
4. **Watch transitions**: Over 30 seconds, you'll see:
   - Sky gradually darkening when rain approaches
   - Clouds appearing (increased turbidity and mie coefficient)
   - Sky brightening when weather clears

### Configuration

To adjust sky effects, modify the parameters in `_get_weather_params()`:

```gdscript
WeatherState.HEAVY_RAIN:
    return {
        "turbidity": 30.0,  # Increase for more dramatic storms
        "mie_coefficient": 0.025,  # Increase for more clouds
        "rayleigh_coefficient": 0.8  # Decrease for darker sky
    }
```

### Technical Notes

#### Why PhysicalSkyMaterial?

1. **Realistic**: Simulates real atmospheric light scattering
2. **Dynamic**: Parameters can be changed at runtime
3. **Performance**: Computed once, rendered efficiently
4. **Flexible**: Wide range of weather appearances with few parameters

#### Parameter Ranges

- **Turbidity**: 0-100 (we use 10-30 for realistic weather)
- **Mie Coefficient**: 0-1 (we use 0.005-0.025 for subtle to heavy clouds)
- **Rayleigh Coefficient**: 0-10 (we use 0.8-2.0 for dark to bright sky)

#### Integration with Existing Weather

The sky changes work seamlessly with existing weather effects:
- **Fog** adds ground-level haze
- **Rain particles** provide visual rain
- **Sky** sets the overall atmosphere and lighting

All three transition together for a cohesive weather experience.

### Future Enhancements

Possible improvements:
- Add time-of-day variations (sunrise/sunset colors)
- Add procedural clouds using volumetric fog
- Vary sun intensity with weather
- Add lightning flashes for storms
- Add wind effects synchronized with weather
