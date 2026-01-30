# Debug Systems

Development and debugging tools.

## Files

### Debug Log Overlay (`debug_log_overlay.gd`)
- **Autoload singleton** - globally accessible
- On-screen debug logging panel
- Message history and filtering
- Performance info display

### Debug Visualization (`debug_visualization.gd`)
- Visual debugging tools
- Chunk border visualization
- Walkability display
- Cluster system visualization

### Debug Narrative UI (`debug_narrative_ui.gd`)
- Narrative system debugging
- Quest state inspection
- Marker visualization
- Testing interface

## Usage

```gdscript
# Debug Log Overlay (autoload)
DebugLogOverlay.log_message("Your debug message")
DebugLogOverlay.log_message("Chunk (%d, %d) loaded" % [x, z])

# Debug Visualization
var debug_viz = DebugVisualization.new()
add_child(debug_viz)

# Debug Narrative UI
var debug_narrative = DebugNarrativeUI.new()
add_child(debug_narrative)
```

## Integration

- Debug tools should not impact production builds
- DebugLogOverlay is an autoload singleton
- Other debug tools are manually added during development
- Can be disabled/removed for release builds

## Note

These are development tools and should be excluded or disabled in production builds.
