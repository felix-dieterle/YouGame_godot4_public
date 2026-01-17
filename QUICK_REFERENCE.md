# Quick Reference - Pause Menu & Settings

## Quick Start

### Desktop Controls
- **ESC** - Open/close pause menu
- **Mouse Click** - Navigate menus

### Mobile Controls  
- **☰ Button** (top-left) - Open settings
- **Tap** - Navigate and adjust settings

## Pause Menu (Desktop & Mobile)

### Open Pause Menu
- **Desktop**: Press ESC
- **Mobile**: Tap ☰ → "Pause Game"

### Options Available
1. **Resume Game** - Return to gameplay
2. **Settings** - Adjust volume and display
3. **Quit to Desktop** - Exit game

## Settings Menu Features

### Display Section
- **Toggle First Person View** - Switch camera perspective
  - First-person (default): See from robot's eyes
  - Third-person: Follow robot from behind

### Audio Section
- **Master Volume** - Adjust game audio (0-100%)
  - Drag slider left to decrease
  - Drag slider right to increase
  - Changes apply immediately

### Game Section (Mobile Only)
- **Pause Game** - Opens main pause menu

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| ESC | Pause/Resume game |
| V | Toggle camera view (in-game) |
| WASD / Arrows | Move player |

## Touch Controls (Mobile)

| Action | Control |
|--------|---------|
| Move | Virtual joystick (bottom-left) |
| Menu | ☰ button (top-left) |
| Camera | Settings → Toggle First Person View |
| Volume | Settings → Volume slider |
| Pause | Settings → Pause Game |

## Tips

### Desktop
- Use ESC for quick pause access
- Adjust volume in pause menu settings
- Click Resume or press ESC again to continue

### Mobile
- All settings in one convenient menu (☰)
- Large touch targets for easy tapping
- Volume adjusts in real-time
- Pause game without losing progress

## Troubleshooting

**Pause menu not appearing?**
- Desktop: Try pressing ESC again
- Mobile: Check if settings menu is open first

**Volume not changing?**
- Ensure system volume is not muted
- Try moving slider to different position
- Changes apply immediately when dragging

**Camera toggle not working?**
- Must be in gameplay (not paused)
- Try from pause menu settings instead
- Mobile: Use settings menu option

## Technical Info

**Files Involved:**
- `scripts/pause_menu.gd` - Main pause functionality
- `scripts/mobile_controls.gd` - Mobile UI and settings
- `scenes/main.tscn` - Scene integration

**Input Actions:**
- `toggle_pause` - ESC key (scancode 4194305)
- `toggle_camera_view` - V key (scancode 86)

**Audio System:**
- Uses AudioServer.set_bus_volume_db()
- Volume converted from linear (0-100) to dB
- Applies to Master audio bus

---

For detailed information, see:
- `FEATURES.md` - Complete feature documentation
- `PAUSE_MENU_IMPLEMENTATION.md` - Technical details
- `PAUSE_MENU_VISUAL_GUIDE.md` - UI specifications
