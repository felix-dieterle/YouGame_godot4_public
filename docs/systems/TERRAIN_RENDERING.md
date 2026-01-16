# Terrain Rendering Update

## Overview
The terrain rendering has been updated to show proper shadows and depth perception, replacing the previous debug-style green/red coloring.

## Changes Made

### Previous Implementation
- **Flat vertex colors**: Bright green for walkable areas, bright red for steep areas
- **No shading**: Simple flat material without shadow interaction
- **Debug-focused**: Clear visualization but not realistic

### New Implementation
- **Height-based coloring**: Natural earthy tones that vary with terrain elevation
- **Proper shading**: Per-pixel shading mode for realistic light interaction
- **Shadow receiving**: Terrain receives shadows from DirectionalLight3D
- **Subtle walkability hints**: Non-walkable areas have a slight brownish tint

## Color Scheme

### Height-Based Variation
The terrain color varies based on elevation:
- **Higher areas**: Lighter green-brown tones
- **Lower areas**: Darker green-brown tones
- **Formula**: `height_factor = (average_height / 40.0) + 0.5`, clamped to [0.3, 0.8]

### Base Color
Earthy green-brown: RGB(0.4, 0.5, 0.3) multiplied by height factor
- Creates natural-looking terrain
- Resembles grass/dirt mixture

### Walkability Indication
- **Walkable areas**: Standard base color
- **Non-walkable areas**: Subtle brownish tint (20% lerp toward brown)
- Much more subtle than the previous bright red, but still provides feedback

## Material Properties
```gdscript
var material = StandardMaterial3D.new()
material.vertex_color_use_as_albedo = true
material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
material.roughness = 0.9
```

### Shading Mode
- **Per-pixel shading**: Enables smooth lighting across terrain
- **No specular**: Matte surface appropriate for natural ground
- **High roughness (0.9)**: Diffuse appearance like dirt/grass

### Shadow Settings
- **Cast shadow**: Disabled (terrain doesn't cast shadows on itself)
- **Receive shadow**: Enabled by default (terrain receives shadows from objects and directional light)

## Visual Benefits

### Depth Perception
1. **Height variation in color**: Immediately shows hills and valleys
2. **Shadows from DirectionalLight3D**: Creates clear depth cues
3. **Normals-based shading**: Slopes appear darker/lighter based on angle to light

### Realism
- Natural color palette
- Realistic shadow interaction
- Smooth shading across terrain cells

### Maintained Functionality
- Walkability information still visible (subtle tint)
- All terrain generation logic unchanged
- Performance characteristics maintained

## Integration with Lighting
The terrain now properly interacts with the DirectionalLight3D in the scene:
- Light angle: Angled from above at ~30-45 degrees
- Shadow mode: Directional shadows enabled
- Shadow distance: 200 units
- The terrain receives these shadows, creating depth perception for:
  - Hills casting shadows on valleys
  - Robot casting shadow on terrain
  - NPCs casting shadows
  - Any placed objects casting shadows

## Comparison
| Aspect | Before | After |
|--------|--------|-------|
| Color scheme | Bright green/red | Natural earthy tones |
| Shading | None | Per-pixel with normals |
| Shadows | Not visible | Fully visible |
| Depth perception | Limited | Excellent |
| Walkability indication | Very obvious | Subtle but present |
| Realism | Debug-like | Natural environment |
