# Mobile Settings Menu Feature

This document describes the mobile settings menu implementation added to the YouGame Godot4 project.

## Overview

A hamburger menu button has been added to the bottom-right corner of the Android app (replacing the previous camera toggle button). When tapped, it opens a settings panel with various options.

## UI Layout

```
┌─────────────────────────────────────────────┐
│                                             │
│                                             │
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
│              │   Actions    │               │
│              │  (coming     │               │
│              │   soon)      │               │
│              │              │               │
│              │   [Close]    │               │
│              └──────────────┘               │
│                                             │
│    (o)                                 ☰    │
│   Joystick                          Menu    │
└─────────────────────────────────────────────┘
```

## Components

### 1. Menu Button (☰)
- **Location**: Bottom-right corner
- **Style**: Circular button with dark gray background (semi-transparent)
- **Icon**: Hamburger menu symbol (☰)
- **Size**: 60x60 pixels
- **Function**: Opens/closes the settings panel

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
var menu_button: Button
var settings_panel: Panel
var settings_visible: bool = false
```

#### Main Functions

1. **`_create_menu_button()`**
   - Creates the hamburger menu button
   - Positions it in bottom-right corner
   - Connects to `_on_menu_button_pressed()`

2. **`_create_settings_panel()`**
   - Creates the settings panel with all UI elements
   - Sets up styling and layout
   - Adds camera toggle and actions sections
   - Initially hidden

3. **`_on_menu_button_pressed()`**
   - Toggles settings panel visibility
   - Updates panel position when shown

4. **`_on_camera_toggle_pressed()`**
   - Calls player's `_toggle_camera_view()` method
   - Closes the settings menu automatically

5. **`_on_close_settings_pressed()`**
   - Hides the settings panel

## User Experience

### Opening the Menu
1. User taps the menu button (☰) in bottom-right corner
2. Settings panel slides/appears in center-bottom of screen
3. Panel displays available settings and actions

### Using Settings
1. User can tap "Toggle First Person View" to switch camera modes
   - Action is executed immediately
   - Menu closes automatically
2. User can tap other options when available

### Closing the Menu
1. User taps "Close" button in settings panel, OR
2. User taps menu button (☰) again

## Future Enhancements

The "Actions" section is designed to accommodate future features:
- Quick action buttons for game mechanics
- Inventory shortcuts
- Game settings (sound, graphics, etc.)
- Character abilities or skills
- Map/navigation tools

## Mobile Optimization

- All buttons use `FOCUS_NONE` to prevent focus issues on mobile
- Touch-friendly sizes (minimum 45-60 pixels)
- High z-index ensures menu appears above game elements
- `MOUSE_FILTER_STOP` prevents touch events from passing through
- Semi-transparent backgrounds for visibility
- Large font sizes (18-24pt) for readability

## Testing Recommendations

When testing on Android:
1. Verify menu button appears in bottom-right
2. Check that tapping opens the settings panel
3. Confirm camera toggle works and closes menu
4. Test panel positioning on different screen sizes
5. Verify touch responsiveness of all buttons
6. Check that panel doesn't interfere with joystick
