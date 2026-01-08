# Debug Overlay System

## Übersicht / Overview

Dieses System wurde hinzugefügt, um herauszufinden, warum das Settings Panel und die First-Person View Toggle nicht sichtbar werden. Es zeigt Debug-Logs transparent über dem Spiel an.

This system was added to investigate why the settings panel and first-person view toggle are not visible. It displays debug logs transparently over the game.

## Komponenten / Components

### 1. DebugLogOverlay (scripts/debug_log_overlay.gd)

Ein transparentes Overlay-System, das Debug-Nachrichten sammelt und anzeigt.

A transparent overlay system that collects and displays debug messages.

#### Features:
- **📋 Toggle Button** (oben links / top left): Zeigt/Versteckt das Debug-Panel / Shows/hides the debug panel
- **🗑 Clear Button** (neben Toggle / next to toggle): Löscht alle Logs / Clears all logs
- **Transparentes Panel**: Schwarzer Hintergrund (75% Transparenz) mit grünem Rand / Black background (75% transparent) with green border
- **Auto-Scroll**: Scrollt automatisch zu neuen Nachrichten / Automatically scrolls to new messages
- **Farbcodierte Nachrichten**: Unterstützt verschiedene Farben für verschiedene Log-Typen / Supports different colors for different log types
- **Maximale Zeilen**: Behält nur die letzten 50 Log-Zeilen / Keeps only the last 50 log lines

#### Verwendung / Usage:

```gdscript
# Von überall im Code aufrufen / Call from anywhere in code
DebugLogOverlay.add_log("My debug message")

# Mit Farbe / With color
DebugLogOverlay.add_log("Error message", "red")
DebugLogOverlay.add_log("Success message", "green")
DebugLogOverlay.add_log("Warning message", "yellow")
DebugLogOverlay.add_log("Info message", "cyan")
```

### 2. Instrumentierung der MobileControls / Mobile Controls Instrumentation

Die `mobile_controls.gd` wurde mit Debug-Ausgaben erweitert, um zu verfolgen:

The `mobile_controls.gd` has been instrumented with debug outputs to track:

- **Menu Button Erstellung**: Position, Größe, z-index / Menu button creation: position, size, z-index
- **Settings Panel Erstellung**: Position, Größe, Sichtbarkeit / Settings panel creation: position, size, visibility
- **Button-Klicks**: Wann Buttons gedrückt werden / Button clicks: when buttons are pressed
- **Kamera-Toggle**: Erfolg oder Fehler beim Umschalten / Camera toggle: success or failure
- **Position Updates**: Wenn UI-Elemente neu positioniert werden / Position updates: when UI elements are repositioned

#### Debug-Nachrichten / Debug Messages:

1. **Beim Start / On startup**:
   ```
   MobileControls._ready() started
   Player reference: Found/NOT FOUND
   Joystick base created
   Creating menu button...
   Menu button configured: z_index=10, size=60x60
   Menu button added to scene tree, visible=true
   Menu button positioned at (x, y), viewport: widthxheight
   Creating settings panel...
   Settings panel configured: z_index=20, visible=false
   Settings panel added to scene tree
   Settings panel positioned at (x, y), size: 300x350
   MobileControls._ready() completed
   ```

2. **Bei Button-Interaktion / On button interaction**:
   ```
   Menu button pressed!
   Settings panel visibility toggled to: true/false
   Close settings button pressed
   Camera toggle pressed
   Camera view toggled / Player not found or method missing!
   ```

3. **Bei Positionsänderungen / On position changes**:
   ```
   Menu button positioned at (x, y), viewport: widthxheight
   Settings panel positioned at (x, y), size: 300x350
   ```

### 3. Instrumentierung des Players / Player Instrumentation

Die `player.gd` wurde mit Debug-Ausgaben für Kamera-Toggle erweitert:

The `player.gd` has been instrumented with debug outputs for camera toggle:

```
Player._toggle_camera_view() called
Camera view toggled to: First Person/Third Person
```

## Integration in die Szene / Scene Integration

Das Debug-Overlay wurde zur `main.tscn` hinzugefügt als:

The debug overlay was added to `main.tscn` as:

```
[node name="DebugLogOverlay" type="Control" parent="."]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
script = ExtResource("8_debug_log")
```

## Verwendung im Spiel / Usage in Game

### Desktop:
1. Spiel starten / Start game
2. Debug-Panel ist sichtbar (oben links) / Debug panel is visible (top left)
3. Alle Debug-Nachrichten werden automatisch angezeigt / All debug messages are automatically displayed
4. Klick auf 📋 zum Ein/Ausblenden / Click 📋 to toggle
5. Klick auf 🗑 zum Löschen der Logs / Click 🗑 to clear logs

### Mobile (Android):
1. Spiel auf dem Gerät installieren / Install game on device
2. Debug-Panel ist beim Start sichtbar / Debug panel is visible at startup
3. Tippen auf 📋 zum Ein/Ausblenden / Tap 📋 to toggle
4. Tippen auf 🗑 zum Löschen / Tap 🗑 to clear
5. Logs zeigen, was mit Menu Button und Settings Panel passiert / Logs show what happens with menu button and settings panel

## Was zu suchen ist / What to Look For

### Problem: Menu Button nicht sichtbar / Menu Button not visible

Suche nach / Look for:
- ❌ `ERROR: menu_button is null in _update_button_position` → Button wurde nicht erstellt / Button was not created
- ✅ `Menu button added to scene tree, visible=true` → Button sollte sichtbar sein / Button should be visible
- Position außerhalb des Bildschirms / Position outside viewport
- z-index Probleme / z-index issues

### Problem: Settings Panel nicht sichtbar / Settings Panel not visible

Suche nach / Look for:
- ❌ `ERROR: settings_panel is null` → Panel wurde nicht erstellt / Panel was not created
- ✅ `Settings panel added to scene tree` → Panel wurde erstellt / Panel was created
- ✅ `Settings panel visibility toggled to: true` → Panel sollte sichtbar sein / Panel should be visible
- Position oder Größenprobleme / Position or size issues

### Problem: First-Person Toggle funktioniert nicht / First-Person Toggle not working

Suche nach / Look for:
- ❌ `Player not found or method missing!` → Player-Referenz fehlt / Player reference missing
- ✅ `Camera view toggled to: First Person` → Toggle funktioniert / Toggle works
- Player-Referenz beim Start / Player reference at startup

## Farb-Code / Color Code

- 🟢 **Green (grün)**: Erfolgreiche Operationen / Successful operations
- 🟡 **Yellow (gelb)**: Ereignisse/Aktionen / Events/Actions
- 🔵 **Cyan (cyan)**: Informationen/Konfiguration / Information/Configuration
- 🔴 **Red (rot)**: Fehler / Errors
- ⚪ **White (weiß)**: Allgemein / General

## Nächste Schritte / Next Steps

1. Spiel starten und Debug-Logs überprüfen / Start game and check debug logs
2. Probleme in den Logs identifizieren / Identify issues in logs
3. Entsprechende Fehler beheben / Fix corresponding errors
4. Debug-Overlay kann nach Fehlerbehebung deaktiviert werden / Debug overlay can be disabled after fixing issues

## Deaktivieren des Debug-Systems / Disabling the Debug System

Nach der Fehlerbehebung / After fixing issues:

1. In `main.tscn`: DebugLogOverlay Node entfernen oder ausblenden / Remove or hide DebugLogOverlay node
2. In `mobile_controls.gd` und `player.gd`: Debug-Logs entfernen / Remove debug logs
3. Oder: `is_visible = false` in `debug_log_overlay.gd` setzen / Or: set `is_visible = false` in `debug_log_overlay.gd`

## Technische Details / Technical Details

- **Singleton Pattern**: DebugLogOverlay verwendet eine statische Instanz / DebugLogOverlay uses a static instance
- **Thread-Safe**: Alle Logs gehen durch die statische Methode / All logs go through static method
- **Performance**: Begrenzt auf 50 Zeilen, automatisches Trimmen / Limited to 50 lines, automatic trimming
- **Z-Index**: 100 für Buttons, 99 für Panel (höchste Ebene) / 100 for buttons, 99 for panel (highest layer)
- **Console Fallback**: Logs werden auch in die Console geschrieben / Logs are also written to console
