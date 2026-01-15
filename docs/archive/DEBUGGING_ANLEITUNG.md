# Anleitung: Settings Panel und First-Person Toggle Debugging
# Instructions: Settings Panel and First-Person Toggle Debugging

## Was wurde implementiert / What Was Implemented

Ein transparentes Debug-Log-System wurde hinzugefügt, um herauszufinden, warum das Settings Panel und der First-Person View Toggle nicht sichtbar werden.

A transparent debug log system has been added to investigate why the settings panel and first-person view toggle are not visible.

## Sofort starten / Quick Start

### Desktop:
```bash
cd /home/runner/work/YouGame_godot4/YouGame_godot4
godot --path . scenes/main.tscn
```

### Android:
```bash
cd /home/runner/work/YouGame_godot4/YouGame_godot4
./build.sh
# Dann APK auf Gerät installieren / Then install APK on device
adb install export/YouGame.apk
```

## Was Sie sehen werden / What You Will See

### 1. Debug-Overlay (oben links / top left)
- **📋 Button**: Ein/Ausschalten des Debug-Panels / Toggle debug panel
- **🗑 Button**: Logs löschen / Clear logs
- **Schwarzes Panel**: Transparentes Log-Fenster mit grünem Rand / Transparent log window with green border

### 2. Debug-Nachrichten / Debug Messages

Beim Start sehen Sie / On startup you'll see:
```
[0.05s] === Debug Log System Started ===
[0.12s] MobileControls._ready() started
[0.13s] Player reference: Found
[0.14s] Joystick base created
[0.15s] Creating menu button...
[0.16s] Menu button configured: z_index=10, size=60x60
[0.17s] Menu button added to scene tree, visible=true
[0.18s] Menu button positioned at (X, Y), viewport: WIDTHxHEIGHT
...
```

## Schritt-für-Schritt Debugging / Step-by-Step Debugging

### Schritt 1: Überprüfen Sie die Initialisierung / Check Initialization

Suchen Sie nach / Look for:
```
✅ MobileControls._ready() started
✅ Player reference: Found (oder NOT FOUND)
✅ Menu button added to scene tree, visible=true
✅ Settings panel added to scene tree
✅ MobileControls._ready() completed
```

**Problem-Indikatoren / Problem Indicators:**
- ❌ `Player reference: NOT FOUND` → Player-Node fehlt / Player node missing
- ❌ Fehlende Nachrichten → Script läuft nicht / Missing messages → Script not running

### Schritt 2: Überprüfen Sie die Positionen / Check Positions

Suchen Sie nach / Look for:
```
Menu button positioned at (X, Y), viewport: WIDTHxHEIGHT
Settings panel positioned at (X, Y), size: 300x350
```

**Berechnen Sie, ob Position gültig ist / Calculate if position is valid:**

Menu Button sollte sein / Menu button should be at:
- X = viewport_width - 80 - 60 (sollte im sichtbaren Bereich sein)
- Y = viewport_height - 120 - 30 (sollte im sichtbaren Bereich sein)

Beispiel / Example:
- Viewport: 1200x960
- Button Position: (1080, 870) ✅ SICHTBAR / VISIBLE
- Button Position: (1300, 870) ❌ AUSSERHALB / OUTSIDE

### Schritt 3: Testen Sie den Menu Button / Test the Menu Button

1. Klicken/Tippen Sie auf ☰ (unten rechts) / Click/Tap on ☰ (bottom right)

2. Suchen Sie im Log nach / Look in log for:
   ```
   ✅ Menu button pressed!
   ✅ Settings panel visibility toggled to: true
   ```

**Problem-Indikatoren / Problem Indicators:**
- ❌ Keine "Menu button pressed!" Nachricht → Button empfängt keine Klicks
  - Mögliche Ursachen / Possible causes:
    - z-index zu niedrig / z-index too low
    - mouse_filter falsch / mouse_filter wrong
    - Position außerhalb Bildschirm / Position outside screen
    - Anderes UI-Element darüber / Other UI element on top

### Schritt 4: Überprüfen Sie das Settings Panel / Check the Settings Panel

Nach dem Klick auf Menu Button / After clicking menu button:

Suchen Sie nach / Look for:
```
✅ Settings panel visibility toggled to: true
✅ Settings panel positioned at (X, Y), size: 300x350
```

**Berechnen Sie Panel-Position / Calculate panel position:**
- X = (viewport_width - 300) / 2 (sollte zentriert sein / should be centered)
- Y = viewport_height - 350 - 120 - 60 - 20

**Problem-Indikatoren / Problem Indicators:**
- Panel öffnet aber ist nicht sichtbar / Panel opens but not visible:
  - Position außerhalb Bildschirm? / Position outside screen?
  - z-index Konflikt mit anderem UI? / z-index conflict with other UI?
  - Größe zu klein? / Size too small?

### Schritt 5: Testen Sie den Camera Toggle / Test the Camera Toggle

1. Öffnen Sie Settings Panel (☰ Button) / Open settings panel (☰ button)
2. Klicken Sie auf "👁 Toggle First Person View"

Suchen Sie im Log nach / Look in log for:
```
✅ Camera toggle pressed
✅ Player._toggle_camera_view() called
✅ Camera view toggled to: First Person
✅ Close settings button pressed
```

**Problem-Indikatoren / Problem Indicators:**
- ❌ `Player not found or method missing!`
  - Player-Referenz beim Start war: `Player reference: NOT FOUND`
  - Lösung: Player-Node zur Szene hinzufügen / Solution: Add player node to scene

## Häufige Probleme und Lösungen / Common Problems and Solutions

### Problem 1: Menu Button ist nicht sichtbar / Menu Button Not Visible

**Diagnose / Diagnosis:**
```
✅ Menu button added to scene tree, visible=true
✅ Menu button positioned at (1500, 870), viewport: 1200x960
```
→ Position X=1500 ist größer als Viewport-Breite 1200! / Position X=1500 is greater than viewport width 1200!

**Lösung / Solution:**
Überprüfen Sie `button_margin_x` in `mobile_controls.gd`:
```gdscript
@export var button_margin_x: float = 80.0  # Zu klein? / Too small?
```

### Problem 2: Settings Panel öffnet nicht / Settings Panel Won't Open

**Diagnose / Diagnosis:**
```
(Kein "Menu button pressed!" im Log)
```
→ Button empfängt keine Touch-Events / Button not receiving touch events

**Lösung / Solution:**
1. Überprüfen Sie z-index:
   ```
   Menu button configured: z_index=10
   ```
   Sollte mindestens 10 sein / Should be at least 10

2. Überprüfen Sie mouse_filter im Code:
   ```gdscript
   menu_button.mouse_filter = Control.MOUSE_FILTER_STOP
   ```

### Problem 3: Settings Panel ist unsichtbar trotz "visible=true" / Settings Panel Invisible Despite "visible=true"

**Diagnose / Diagnosis:**
```
✅ Settings panel visibility toggled to: true
✅ Settings panel positioned at (-100, 440), size: 300x350
```
→ Position X=-100 ist außerhalb des Bildschirms! / Position X=-100 is outside screen!

**Lösung / Solution:**
Überprüfen Sie die Berechnung in `_update_settings_panel_position()`:
```gdscript
var panel_x = (viewport_size.x - PANEL_WIDTH) / 2
```

### Problem 4: Camera Toggle hat keine Wirkung / Camera Toggle Has No Effect

**Diagnose / Diagnosis:**
```
✅ Camera toggle pressed
❌ Player not found or method missing!
```

**Lösung / Solution:**
1. Player-Node zur Szene hinzufügen / Add player node to scene
2. Sicherstellen dass Player `player.gd` Script hat / Ensure player has `player.gd` script
3. Überprüfen Sie Parent-Struktur / Check parent structure:
   ```
   Main (Node3D)
   ├── Player (CharacterBody3D)
   └── MobileControls (Control)
   ```

## Debug-Informationen sammeln / Collecting Debug Information

### Für Bug-Report:

1. **Machen Sie einen Screenshot** des Debug-Panels / Take a screenshot of debug panel
2. **Kopieren Sie die Logs** (erste 20 Zeilen) / Copy the logs (first 20 lines)
3. **Notieren Sie Ihr Gerät** / Note your device:
   - Bildschirmauflösung / Screen resolution
   - Android Version / Android version
   - Godot Version

### Log-Beispiel für Bug-Report:

```
=== System Info ===
Device: Samsung Galaxy S10
Screen: 1440x3040
Android: 12
Godot: 4.3

=== Debug Logs ===
[0.05s] === Debug Log System Started ===
[0.12s] MobileControls._ready() started
[0.13s] Player reference: NOT FOUND  ← PROBLEM!
[0.17s] Menu button added to scene tree, visible=true
[0.18s] Menu button positioned at (1380, 2950), viewport: 1440x3040
[2.45s] Menu button pressed!
[2.46s] Settings panel visibility toggled to: true
[5.12s] Camera toggle pressed
[5.13s] Player not found or method missing!  ← PROBLEM!
```

## Nach der Fehlerbehebung / After Fixing

### Debug-System deaktivieren / Disable Debug System

1. **Option 1**: Logs entfernen / Remove logs
   - Alle `DebugLogOverlay.add_log()` Aufrufe entfernen / Remove all `DebugLogOverlay.add_log()` calls
   - `debug_log_overlay.gd` aus `main.tscn` entfernen / Remove `debug_log_overlay.gd` from `main.tscn`

2. **Option 2**: Debug-Panel verstecken / Hide debug panel
   - In `debug_log_overlay.gd` ändern / Change in `debug_log_overlay.gd`:
     ```gdscript
     var is_visible: bool = false  # Startet versteckt / Starts hidden
     ```

3. **Option 3**: Behalten für Entwicklung / Keep for development
   - Nützlich für zukünftige Probleme / Useful for future issues
   - Benutzer können mit 📋 Button aktivieren / Users can enable with 📋 button

## Weitere Hilfe / Further Help

Siehe auch / See also:
- `DEBUG_OVERLAY_SYSTEM.md` - Detaillierte Systembeschreibung / Detailed system description
- `DEBUG_OVERLAY_VISUAL_GUIDE.md` - Visuelle Anleitung / Visual guide
- `MOBILE_MENU.md` - Mobile Menu Dokumentation / Mobile menu documentation

## Kontakt / Contact

Bei Fragen öffnen Sie ein Issue auf GitHub mit:
For questions, open a GitHub issue with:
- Screenshot des Debug-Panels / Screenshot of debug panel
- Kopie der relevanten Logs / Copy of relevant logs
- Geräteinformationen / Device information
