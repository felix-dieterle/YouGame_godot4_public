# Mobile Controls Feature

This document describes the mobile controls implementation in the YouGame Godot4 project.

## Overview

The mobile controls include:
1. A movement joystick in the bottom-left corner for character movement
2. A look/camera joystick in the bottom-right corner for camera control
3. A hamburger menu button for accessing settings

## UI Layout

```
┌─────────────────────────────────────────────┐
│ ☰ Menu                                      │
│                                             │
│                                             │
│                  GAME VIEW                  │
│                                             │
│              ┌──────────────┐               │
│              │  Settings    │               │
│              ├──────────────┤               │
│              │              │               │
│              │ 👁 Toggle    │               │
│              │ First Person │               │
│              │              │               │
│              ├──────────────┤               │
│              │   ⏸ Pause    │               │
│              │              │               │
│              │   [Close]    │               │
│              └──────────────┘               │
│                                             │
│    (o)                              (o)     │
│  Movement                          Look     │
│  Joystick                        Joystick   │
└─────────────────────────────────────────────┘
```

## Components

### 1. Movement Joystick (Left)
- **Location**: Bottom-left corner
- **Style**: Circular base (dark gray) with movable stick
- **Radius**: 80 pixels
- **Function**: Controls character movement (up/down/left/right)
- **Input**: Touch and drag to move character
- **Deadzone**: 20% to prevent drift

### 2. Look/Camera Joystick (Right)
- **Location**: Bottom-right corner, positioned with spacing from version/time labels
- **Style**: Circular base (reddish tint) with movable stick
- **Radius**: 80 pixels
- **Function**: Controls camera rotation (pan up/down/left/right)
- **Input**: Touch and drag to look around
- **Deadzone**: 20% to prevent drift
- **Color**: Slightly reddish tint to differentiate from movement joystick

### 3. Menu Button (☰)
- **Location**: Top-left corner (next to debug buttons)
- **Style**: Circular button with dark gray background (semi-transparent)
- **Icon**: Hamburger menu symbol (☰)
- **Size**: 60x60 pixels
- **Function**: Opens the pause menu

### 2. Settings Panel
- **Appearance**: Dark panel with rounded corners and border
- **Position**: Centered horizontally, positioned above the menu button
- **Size**: 300x350 pixels
- **Visibility**: Hidden by default, shown when menu button is tapped
- **Z-Index**: 20 (appears above other UI elements)

### 3. Settings Panel Contents

#### Title
- Text: "Settings"
- Size: 24pt font
- Color: White
- Alignment: Center

#### Camera Toggle Button
- Text: "👁 Toggle First Person View"
- Size: 50 pixels height, 18pt font
- Style: Dark gray button with hover/press states
- Function: Switches between first-person and third-person camera views
- Behavior: Automatically closes the menu after toggling

#### Actions Section
- Label: "Actions"
- Size: 20pt font
- Placeholder text: "(More actions coming soon)"
- Purpose: Reserved for future game actions

#### Close Button
- Text: "Close"
- Size: 45 pixels height, 18pt font
- Style: Red-tinted button with hover/press states
- Function: Closes the settings panel

## Implementation Details

### File: `scripts/mobile_controls.gd`

#### Key Variables
```gdscript
# Movement joystick
var joystick_base: Control
var joystick_stick: Control
var joystick_active: bool = false
var joystick_vector: Vector2 = Vector2.ZERO

# Look/camera joystick
var look_joystick_base: Control
var look_joystick_stick: Control
var look_joystick_active: bool = false
var look_joystick_vector: Vector2 = Vector2.ZERO

# Menu button and settings panel
var menu_button: Button
var settings_panel: Panel
var settings_visible: bool = false
```

#### Main Functions

1. **`_create_look_joystick()`**
   - Creates the look/camera joystick on the right side
   - Positions it with proper spacing from version/time labels
   - Uses reddish tint to differentiate from movement joystick

2. **`get_input_vector()`**
   - Returns the movement joystick input as Vector2
   - Used by player for character movement

3. **`get_look_vector()`**
   - Returns the look joystick input as Vector2
   - Used by player for camera rotation

4. **`_update_look_joystick()`**
   - Updates look joystick stick position based on touch
   - Applies deadzone and normalization

### File: `scripts/player.gd`

#### Camera Rotation Variables
```gdscript
var camera_rotation_x: float = 0.0  # Vertical rotation (pitch)
var camera_rotation_y: float = 0.0  # Horizontal rotation (yaw)
@export var camera_sensitivity: float = 0.5
@export var camera_max_pitch: float = 80.0  # Maximum vertical look angle
```

#### Camera Control Functions

1. **`_physics_process(delta)`**
   - Reads look joystick input from mobile_controls
   - Applies rotation to camera based on joystick input
   - Updates camera position/rotation in real-time

2. **`_update_camera_rotation()`**
   - Applies pitch and yaw rotation to camera
   - In first-person: rotates camera directly
   - In third-person: orbits camera around player

3. **`_toggle_camera_view()`**
   - Resets camera rotation when switching views
   - Prevents jarring transitions

## User Experience

### Movement Control
1. Touch and drag the left joystick to move character
2. Character moves in the direction of the joystick
3. Release to stop moving

### Camera Control (NEW)
1. Touch and drag the right joystick to look around
2. Horizontal movement (left/right) rotates camera horizontally (yaw)
3. Vertical movement (up/down) rotates camera vertically (pitch)
4. Works in both first-person and third-person views:
   - **First-person**: Direct camera rotation for looking around
   - **Third-person**: Camera orbits around the player
5. Release to stop rotating

### Opening the Menu
1. User taps the menu button (☰) in top-left corner
2. Pause menu opens with game options
3. Menu displays available settings and actions

### Using Settings
1. User can tap "Toggle First Person View" to switch camera modes
   - Action is executed immediately
   - Menu closes automatically
2. User can tap other options when available

### Closing the Menu
1. User taps "Close" button in settings panel, OR
2. User taps menu button (☰) again

## Future Enhancements

Potential improvements for mobile controls:
- Customizable joystick positions and sizes
- Sensitivity settings for camera rotation
- Optional inverted Y-axis for camera
- Haptic feedback on touch
- Visual indicators for camera rotation limits
- Touch gesture support (pinch to zoom, swipe, etc.)

## Mobile Optimization

- All buttons use `FOCUS_NONE` to prevent focus issues on mobile
- Touch-friendly sizes (minimum 45-60 pixels)
- High z-index ensures menu appears above game elements
- `MOUSE_FILTER_STOP` prevents touch events from passing through
- Semi-transparent backgrounds for visibility
- Large font sizes (18-24pt) for readability
- Dual joystick support with simultaneous touch tracking
- Independent touch indices for each joystick
- Proper spacing between joysticks and UI elements (version/time labels)
- Color differentiation between movement (gray) and look (reddish) joysticks

## Testing Recommendations

When testing on Android:
1. Verify both joysticks appear correctly (left and right)
2. Test movement joystick for character movement
3. Test look joystick for camera rotation in both views
4. Confirm joysticks don't overlap with version/time labels
5. Check that both joysticks can be used simultaneously
6. Verify menu button functionality
7. Test camera toggle between first-person and third-person
8. Check touch responsiveness on different screen sizes
9. Verify camera rotation limits (max pitch angle)
10. Test that camera rotation resets when switching views

### Automated Testing Note

When creating automated tests for MobileControls, the control must be configured with proper anchors to match the main scene configuration:

```gdscript
mobile_controls.set_anchors_preset(Control.PRESET_FULL_RECT)
mobile_controls.anchor_right = 1.0
mobile_controls.anchor_bottom = 1.0
mobile_controls.grow_horizontal = Control.GROW_DIRECTION_BOTH
mobile_controls.grow_vertical = Control.GROW_DIRECTION_BOTH
```

Without these anchors, the MobileControls node has zero size and joystick elements won't be positioned correctly, causing tests to fail even though the actual game implementation works fine. See `tests/test_mobile_controls.gd` for a complete example.
