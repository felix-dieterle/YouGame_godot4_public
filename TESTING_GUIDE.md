# Testing Guide: Scene Debug Logging

This guide helps you test the new scene detection and version logging features.

## Quick Test

1. **Open the project in Godot:**
   ```bash
   godot --path /path/to/YouGame_godot4_public
   ```

2. **Run the main scene:**
   - Press F5 or click "Play" button
   - OR: `godot --path . scenes/main.tscn`

3. **Check the debug log:**
   - Click the 📋 button in the top-left corner
   - You should see:
     ```
     [0.05s] === Debug Log System Started ===
     [0.06s] Game Version: v1.0.16
     [0.07s] Current Scene: Main
     [0.08s] Scene Path: res://scenes/main.tscn
     [0.09s] Scene Type: MAIN SCENE
     [0.10s] Version Label: visible=true, text='Version: v1.0.16'
     [0.11s] Version Label position: (0, 0), z_index=100
     ```

4. **Check the console output:**
   - You should see:
     ```
     [DEBUG] DebugLogOverlay: Running as AUTOLOAD SINGLETON
     ```

5. **Verify version label:**
   - Look at the bottom-right corner of the screen
   - You should see: "Version: v1.0.16"

## Detailed Tests

### Test 1: Main Scene Detection

**Steps:**
1. Run `scenes/main.tscn`
2. Open debug log (📋 button)

**Expected Results:**
- ✅ "Current Scene: Main" appears
- ✅ "Scene Path: res://scenes/main.tscn" appears
- ✅ "Scene Type: MAIN SCENE" appears in green
- ✅ Console shows "Running as AUTOLOAD SINGLETON"

### Test 2: Demo Narrative Scene Detection

**Steps:**
1. Run `scenes/demo_narrative.tscn`
2. Open debug log (📋 button)

**Expected Results:**
- ✅ "Current Scene: Main" appears (scene root is named "Main")
- ✅ "Scene Path: res://scenes/demo_narrative.tscn" appears
- ✅ "Scene Type: DEMO NARRATIVE SCENE" appears in green
- ✅ Console shows "Running as AUTOLOAD SINGLETON"

### Test 3: Version Display

**Steps:**
1. Run any scene
2. Open debug log (📋 button)
3. Look at bottom-right corner

**Expected Results:**
- ✅ "Game Version: v1.0.16" appears in debug log (cyan color)
- ✅ "Version Label: visible=true, text='Version: v1.0.16'" appears
- ✅ Version label visible in bottom-right corner: "Version: v1.0.16"

### Test 4: No Duplicate Warnings

**Steps:**
1. Run `scenes/main.tscn`
2. Check console output

**Expected Results:**
- ✅ Console shows "Running as AUTOLOAD SINGLETON"
- ❌ Console does NOT show "Running as SCENE NODE"
- ❌ Console does NOT show duplicate warnings

### Test 5: Debug Panel Functionality

**Steps:**
1. Run any scene
2. Click 📋 button to toggle debug panel
3. Click 🗑 button to clear logs

**Expected Results:**
- ✅ Panel shows/hides when 📋 clicked
- ✅ Logs are cleared when 🗑 clicked
- ✅ "=== Log Cleared ===" message appears after clearing

## Troubleshooting

### Issue: Version doesn't appear in debug log

**Check:**
1. Look for "Game Version: v1.0.16" in the log
2. Look for "Version Label: visible=..." in the log

**If missing:**
- Check project.godot has `config/version="1.0.16"`
- Check console for errors during DebugLogOverlay initialization

### Issue: Scene type shows "UNKNOWN/OTHER SCENE"

**This is normal if:**
- You're running a test scene (e.g., `tests/test_scene.tscn`)
- You're running a custom scene

**The log will still show:**
- Current scene name
- Scene path
- Just won't identify it as MAIN or DEMO NARRATIVE

### Issue: Console shows "Running as SCENE NODE"

**This means:**
- There's still a duplicate DebugLogOverlay somewhere
- Check all scene files for nodes with script="res://scripts/debug_log_overlay.gd"

**Fix:**
- Remove the node from the scene file
- DebugLogOverlay should ONLY be in project.godot as an autoload

### Issue: Version label not visible on screen

**Check in debug log:**
```
Version Label: visible=true, text='Version: v1.0.16'
Version Label position: (0, 0), z_index=100
```

**If visible=false:**
- There may be a bug in _create_version_label()

**If visible=true but not on screen:**
- Check if another UI element is covering it
- Check if position is off-screen
- Check z_index conflicts

## Color Guide

Debug log uses colors to highlight different types of information:

- **White** - Standard messages
- **Cyan** - Version information
- **Yellow** - Scene information
- **Green** - Positive status (scene type identified)
- **Orange** - Warnings or unknown states
- **Red** - Errors or critical warnings

## Manual Testing Checklist

Use this checklist to verify all features:

- [ ] Main scene loads without errors
- [ ] Demo narrative scene loads without errors
- [ ] Debug log shows "Game Version: v1.0.16"
- [ ] Debug log shows correct scene name for main.tscn
- [ ] Debug log shows correct scene name for demo_narrative.tscn
- [ ] Debug log shows "Scene Type: MAIN SCENE" for main.tscn
- [ ] Debug log shows "Scene Type: DEMO NARRATIVE SCENE" for demo_narrative.tscn
- [ ] Version label visible in bottom-right corner
- [ ] Version label shows "Version: v1.0.16"
- [ ] Console shows "Running as AUTOLOAD SINGLETON"
- [ ] Console does NOT show duplicate warnings
- [ ] 📋 button toggles debug panel
- [ ] 🗑 button clears logs
- [ ] All log entries have timestamps
- [ ] All log entries have correct colors

## Reporting Issues

If you find issues, please report:

1. **What you did:** (e.g., "Ran main scene")
2. **What you expected:** (e.g., "Version should appear in debug log")
3. **What happened:** (e.g., "Version label shows visible=false")
4. **Console output:** Copy any error messages
5. **Debug log output:** Screenshot or copy the log text

## Files to Review

If you want to understand the implementation:

1. `scripts/debug_log_overlay.gd` - Main implementation
2. `SCENE_DEBUG_LOGGING.md` - Detailed documentation
3. `SUMMARY.md` - Implementation summary
4. `scenes/main.tscn` - Verify no duplicate DebugLogOverlay node
5. `project.godot` - Verify DebugLogOverlay in [autoload] section

## Success Criteria

All tests pass if you see:
- ✅ Scene name and type in debug log
- ✅ Version in debug log
- ✅ Version label on screen
- ✅ "AUTOLOAD SINGLETON" in console
- ✅ No duplicate warnings
