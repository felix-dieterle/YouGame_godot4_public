# UI Systems

User interface components and overlays.

## Files

### UI Manager (`ui_manager.gd`)
- Main UI controller
- Status display (version, chunk info)
- Loading messages
- Time speed controls
- Coordinates with other UI elements

### Pause Menu (`pause_menu.gd`)
- Game pause functionality
- Menu navigation
- Settings and options

### Mobile Controls (`mobile_controls.gd`)
- On-screen joystick controls for mobile
- Left joystick: Movement
- Right joystick: Camera look
- Touch input handling

### Minimap Overlay (`minimap_overlay.gd`)
- Minimap display
- Player position indicator
- Explored/unexplored areas
- Performance optimized

### Ruler Overlay (`ruler_overlay.gd`)
- Distance measurement tool
- Debug/development utility
- World unit measurements

### Direction Arrows (`direction_arrows.gd`)
- Navigation arrows to points of interest
- Points to: Water, Crystals, Mountains
- Dynamic direction updates

## Usage

```gdscript
# UI components are typically in main scene
# Access via references or autoload if needed

# Mobile controls
var mobile_controls = MobileControls.new()
add_child(mobile_controls)

# Direction arrows
var arrows = DirectionArrows.new()
add_child(arrows)
```

## Integration

- UI Manager coordinates all UI elements
- Mobile controls integrate with player movement
- Direction arrows use crystal/chunk data
- Minimap tracks player position and exploration
