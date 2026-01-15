# Menu Button Visibility Debug Guide

## Problem Statement
The debug log window and buttons (📋 and 🗑) are visible, but the mobile menu button (☰) is not visible even though the logs indicate it should be within the viewport.

## What We've Added

### Comprehensive Debug Logging
We've enhanced the `MobileControls` script to log detailed information about:

1. **Control Node Information** (MobileControls itself)
   - Position and global_position
   - Size
   - Anchor settings (left, right, top, bottom)
   - Offset settings
   - Viewport size
   - Clipping status
   - Mouse filter setting

2. **Menu Button Information**
   - Position (relative to parent)
   - Global position (absolute screen coordinates)
   - Size
   - Visibility status
   - Z-index
   - Whether it's visible in the scene tree
   - Modulate values (for transparency)
   - Calculated bounds (exact rectangle on screen)
   - Full viewport visibility check

## How to Use This Debug Information

### Step 1: Run the Application
Build and run the application as usual:
```bash
./build.sh
adb install export/YouGame.apk
adb logcat | grep DEBUG
```

Or on desktop:
```bash
godot --path . scenes/main.tscn
```

### Step 2: Check the Debug Log Window
The debug log window (📋 button in top-left) will show comprehensive information when the app starts.

### Step 3: Analyze the Logs

Look for these sections in the debug log:

#### Section 1: MobileControls Control Info
```
=== MobileControls Control Info ===
Control position: (0, 0)                    ← Should be (0, 0) with full-screen anchors
Control size: 1440x3040                     ← Should match viewport size
Control global_position: (0, 0)             ← Should be (0, 0)
Viewport size: 1440x3040                    ← Your screen resolution
anchor_left: 1.00, anchor_right: 1.00       ← Should be 0.00 and 1.00
anchor_top: 1.00, anchor_bottom: 1.00       ← Should be 0.00 and 1.00
offset_left: 0, offset_right: 0             ← Should be 0, 0
offset_top: 0, offset_bottom: 0             ← Should be 0, 0
clip_contents: false                        ← Should be false
mouse_filter: 2 (0=STOP, 1=PASS, 2=IGNORE) ← Should be 2 (IGNORE)
```

**What to Check:**
- ✅ Anchors should be (0, 1) for left/right and (0, 1) for top/bottom
- ✅ Offsets should all be 0
- ✅ Control size should match viewport size
- ❌ If clip_contents is true, the button might be clipped
- ❌ If global_position is not (0, 0), the control is offset

#### Section 2: Menu Button Info
```
=== Menu Button Info ===
Button position: (1300, 2890)               ← Relative to parent (MobileControls)
Button global_position: (1300, 2890)        ← Absolute screen position
Button size: 60x60                          ← Should be 60x60
Button visible: true, z_index: 10           ← visible should be true
Button is_visible_in_tree: true             ← Should be true
Button modulate: (1, 1, 1, 1)              ← Should be (1, 1, 1, 1) - fully opaque
Button self_modulate: (1, 1, 1, 1)         ← Should be (1, 1, 1, 1) - fully opaque
Button bounds: (1300, 2890) to (1360, 2950) ← Should be within viewport
Button top-left in viewport: true              ← Should be true (GREEN)
Button fully in viewport: true                  ← May be false (YELLOW) if extends beyond
```

**What to Check:**
- ✅ `visible` should be `true`
- ✅ `is_visible_in_tree` should be `true`
- ✅ `modulate` should be `(1, 1, 1, 1)` - any value less than 1 for the alpha (4th value) makes it transparent
- ✅ `Button top-left in viewport` should be `true` (shown in GREEN) - this is the critical check
- ⚠️ `Button fully in viewport` may be `false` (YELLOW) - this is OK if button extends slightly beyond bottom edge
- ❌ If `Button top-left in viewport` is `false` (RED), the button is off-screen
- ❌ If modulate alpha is 0, the button is invisible

**Important Note:** The button is positioned to vertically align its center with the joystick center. This means it may extend slightly beyond the bottom edge of the viewport. This is intentional and should not affect visibility. The important check is `Button top-left in viewport`.

#### Section 3: Button Positioning Updates
```
Menu button positioned at (1300, 2890), viewport: 1440x3040
Menu button global_position: (1300, 2890)
Menu button in viewport bounds: true
```

**What to Check:**
- The button should be in the bottom-right area
- Expected position calculation:
  - X: `viewport_width - button_margin_x - button_size`
  - Y: `viewport_height - joystick_margin_y - (button_size / 2)`
- With defaults (margin_x=80, margin_y=120, size=60):
  - X: 1440 - 80 - 60 = 1300 ✓
  - Y: 3040 - 120 - 30 = 2890 ✓

## Common Issues and Solutions

### Issue 1: Button is Off-Screen
**Symptoms:** "Button fully in viewport: false" (RED)

**Possible Causes:**
- Margin values are too large for the screen size
- Viewport size detection is incorrect

**Solution:**
- Adjust `@export` variables in scene editor or script:
  - Reduce `button_margin_x`
  - Reduce `joystick_margin_y`

### Issue 2: Button is Transparent
**Symptoms:** Button position is correct, but modulate shows alpha < 1

**Possible Causes:**
- Accidentally set modulate somewhere
- Parent control has modulate set

**Solution:**
- Check if MobileControls control has modulate set
- Ensure no code sets modulate on the button

### Issue 3: Button is Behind Another Element
**Symptoms:** Button is in viewport, visible, opaque, but still not clickable

**Possible Causes:**
- Another UI element with higher z-index is covering it
- Another full-screen Control is blocking mouse events

**Solution:**
- Check z-index of all Control nodes:
  - DebugLogOverlay buttons: z-index 100
  - Settings panel: z-index 20
  - Menu button: z-index 10 ← might need to increase
  - Other controls: check their z-index values
- Ensure other Control nodes have `mouse_filter = MOUSE_FILTER_IGNORE`

### Issue 4: Control Node is Offset
**Symptoms:** MobileControls global_position is not (0, 0)

**Possible Causes:**
- Anchors are not set correctly
- Offsets are not 0
- Parent node is positioned incorrectly

**Solution:**
- Verify in scene file that MobileControls has:
  ```
  anchor_right = 1.0
  anchor_bottom = 1.0
  offset_left = 0
  offset_right = 0
  offset_top = 0
  offset_bottom = 0
  ```

### Issue 5: Button is Clipped
**Symptoms:** clip_contents is true, button is near edge

**Solution:**
- Set `clip_contents = false` on MobileControls
- Ensure button position has enough margin from edges

## Testing Checklist

After reviewing the logs, check:

- [ ] MobileControls anchors are (0, 1, 0, 1)
- [ ] MobileControls offsets are all 0
- [ ] MobileControls global_position is (0, 0)
- [ ] MobileControls clip_contents is false
- [ ] Button visible is true
- [ ] Button is_visible_in_tree is true
- [ ] Button modulate is (1, 1, 1, 1)
- [ ] Button top-left in viewport is true (GREEN) ← CRITICAL
- [ ] Button global_position is reasonable for viewport size
- [ ] Button z_index is appropriate (10 or higher)

## Next Steps

1. **Run the application** and collect the debug logs
2. **Compare the actual logs** with the expected values above
3. **Identify the discrepancy** between expected and actual values
4. **Apply the appropriate solution** from the Common Issues section
5. **Report findings** with:
   - Screenshot of debug log window
   - Device information (screen resolution, OS)
   - Any unexpected values from the logs

## Additional Information

### Viewport vs Screen Size
- On mobile devices, viewport size may differ from physical screen size due to:
  - Status bar
  - Navigation bar
  - Screen notches
  - Safe area insets

If the button is positioned correctly but still not visible, check if system UI is covering it.

### Z-Index Explanation
Higher z-index values render on top:
- 102: Settings panel (highest - when opened)
- 101: Menu button, Debug narrative button
- 100: Debug log buttons
- 99: Debug log panel
- 0: Status labels (lowest - default)

**Note**: The menu button and other UI buttons now use z-index 101+ to ensure they render above the debug overlay (99-100) and are always visible to the user.

### Mouse Filter Explanation
- `MOUSE_FILTER_STOP (0)`: Receives and blocks mouse events
- `MOUSE_FILTER_PASS (1)`: Receives mouse events but lets them through
- `MOUSE_FILTER_IGNORE (2)`: Ignores mouse events completely

The MobileControls control uses IGNORE so it doesn't block events, but its children (buttons) use STOP to receive clicks.

## Contact
If the issue persists after reviewing the logs, please open a GitHub issue with:
- Complete debug log output (copy from debug window)
- Device information
- Screenshots showing the problem
- Any error messages from `adb logcat`
