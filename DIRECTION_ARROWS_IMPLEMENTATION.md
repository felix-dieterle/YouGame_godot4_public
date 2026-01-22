# Direction Arrows Implementation

## Overview

A visual navigation system that displays arrows around the player pointing to important locations in the game world.

## Features

The direction arrows system displays three color-coded arrows that help players navigate to:

1. **Water/Ocean** (Blue Arrow)
   - Points to the nearest ocean chunk
   - Labeled "Wasser"
   
2. **Crystals** (Purple/Pink Arrow)
   - Points to the nearest crystal
   - Labeled "Kristall"
   
3. **Unique Mountain** (Gray Arrow)
   - Points to the unique mountain location
   - Labeled "Berg"

## Visual Design

### Arrow Positioning
- Arrows appear 150 pixels from the screen center
- Positioned in a circle around the player's view
- Automatically avoid the minimap area in the top-right corner

### Arrow Appearance
- **Triangle Shape**: 30-pixel sized triangles pointing toward targets
- **White Outline**: Each arrow has a white border for visibility
- **Color Coding**:
  - Water: `Color(0.2, 0.5, 1.0, 0.8)` - Blue with 80% opacity
  - Crystal: `Color(0.8, 0.2, 0.8, 0.8)` - Purple/Pink with 80% opacity
  - Mountain: `Color(0.6, 0.6, 0.6, 0.8)` - Gray with 80% opacity

### Distance Labels
- Each arrow displays the target name and distance in meters
- Format: "[Name]\n[Distance]m"
- Example: "Wasser\n142m"
- Labels appear just beyond the arrow tip
- Text has a black shadow for improved visibility

## Behavior

### Update Frequency
- Targets are recalculated every 1 second for performance
- Arrow positions are updated every frame for smooth rotation

### Visibility Rules
- Arrows only appear when targets exist
- Arrows hide when the player is within 10 meters of the target
- All three arrows can be visible simultaneously if targets are available

### Target Detection

#### Nearest Water/Ocean
- Scans all loaded chunks for ocean biomes (`chunk.is_ocean == true`)
- Ocean chunks are at elevation `<= Chunk.OCEAN_LEVEL` (currently -8.0)
- Points to the center of the nearest ocean chunk

#### Nearest Crystal
- Scans all `placed_crystals` arrays in loaded chunks
- Includes all crystal types (Mountain Crystal, Emerald, Garnet, Ruby, Amethyst, Sapphire)
- Points to the exact position of the nearest crystal instance

#### Unique Mountain
- Uses the static `Chunk.mountain_center_chunk_x/z` coordinates
- Mountain is uniquely determined by chunk hash: `(hash % 73) == 42`
- Located within 900 units from spawn (~28 chunks)
- Mountain range extends 11 chunks in all directions from center

## Technical Implementation

### Components

**File**: `scripts/direction_arrows.gd`
**Class**: `DirectionArrows` (extends Control)

### Dependencies
- Player node for position
- WorldManager for chunk access
- Camera3D for screen-space projection
- Chunk class for constants and mountain coordinates

### Screen-Space Projection
The arrows use a custom projection system:
1. Calculate 3D direction from player to target
2. Project onto camera's horizontal plane (ignoring vertical component)
3. Convert to 2D screen direction using camera's forward and right vectors
4. Position arrow on circle around screen center

### Performance Considerations
- Z-index: 60 (above most UI, below pause menu)
- Mouse filter: IGNORE (doesn't block input)
- Target update: 1 second intervals
- Only processes when arrows are visible

## Integration

### Scene Setup
Added to `scenes/main.tscn` as a Control node:

```gdscript
[node name="DirectionArrows" type="Control" parent="." groups=["DirectionArrows"]]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
z_index = 60
script = ExtResource("13_direction_arrows")
```

### API

```gdscript
# Toggle arrow visibility
set_arrows_visible(visible: bool)
toggle_arrows()
```

## Future Enhancements

Possible improvements:
- Add keybind or button to toggle arrows on/off
- Make arrow size/distance configurable via game settings
- Add arrows for other points of interest (NPCs, quest markers)
- Implement fade-in/fade-out animations
- Add arrow pulsing effect for very distant targets
- Customizable colors per user preference
