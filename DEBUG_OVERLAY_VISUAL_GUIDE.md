# Debug Overlay - Visual Guide

## Screenshot Mock-up / Bildschirm-Vorschau

```
┌─────────────────────────────────────────────────────────────────────────┐
│ 📋 🗑                          YouGame - Debug Mode                     │
│ ┌───────────────────────────────────────────────────────────────────┐  │
│ │ [0.05s] === Debug Log System Started ===                          │  │
│ │ [0.12s] MobileControls._ready() started                          │  │
│ │ [0.13s] Player reference: Found                                  │  │
│ │ [0.14s] Joystick base created                                    │  │
│ │ [0.15s] Creating menu button...                                  │  │
│ │ [0.16s] Menu button configured: z_index=10, size=60x60          │  │
│ │ [0.17s] Menu button added to scene tree, visible=true           │  │
│ │ [0.18s] Menu button positioned at (1080, 870), viewport: 1200x960│  │
│ │ [0.19s] Creating settings panel...                               │  │
│ │ [0.20s] Settings panel configured: z_index=20, visible=false     │  │
│ │ [0.21s] Settings panel added to scene tree                       │  │
│ │ [0.22s] Settings panel positioned at (450, 440), size: 300x350  │  │
│ │ [0.23s] MobileControls._ready() completed                        │  │
│ │                                                                   │  │
│ │ [2.45s] Menu button pressed!                                     │  │
│ │ [2.46s] Settings panel visibility toggled to: true               │  │
│ │ [2.47s] Settings panel positioned at (450, 440), size: 300x350  │  │
│ │                                                                   │  │
│ │ [5.12s] Camera toggle pressed                                    │  │
│ │ [5.13s] Player._toggle_camera_view() called                      │  │
│ │ [5.14s] Camera view toggled to: First Person                     │  │
│ │ [5.15s] Close settings button pressed                            │  │
│ └───────────────────────────────────────────────────────────────────┘  │
│                                                                          │
│                          🐛 (Debug Narrative)                            │
│                                                                          │
│                                                                          │
│                                                                          │
│                        GAME VIEW / SPIELANSICHT                          │
│                                                                          │
│                                                                          │
│                                                                          │
│                                                                          │
│                  ┌──────────────┐                                        │
│                  │  Settings    │  ← Settings Panel (when visible)      │
│                  ├──────────────┤                                        │
│                  │ 👁 Toggle    │                                        │
│                  │ First Person │                                        │
│                  │              │                                        │
│                  │   [Close]    │                                        │
│                  └──────────────┘                                        │
│                                                                          │
│    (o)                                                         ☰        │
│   Joystick                                              Menu Button      │
└─────────────────────────────────────────────────────────────────────────┘
```

## Farbcodierung im Log / Color Coding in Log

Die Logs werden mit verschiedenen Farben angezeigt:
The logs are displayed with different colors:

- **🟡 Yellow (Gelb)**: Ereignisse wie Button-Klicks / Events like button clicks
  - `MobileControls._ready() started`
  - `Player reference: Found`
  - `Menu button pressed!`

- **🟢 Green (Grün)**: Erfolgreiche Operationen / Successful operations
  - `Joystick base created`
  - `Menu button added to scene tree, visible=true`
  - `Settings panel added to scene tree`
  - `MobileControls._ready() completed`
  - `Camera view toggled to: First Person`

- **🔵 Cyan**: Informationen und Konfiguration / Information and configuration
  - `Creating menu button...`
  - `Menu button configured: z_index=10, size=60x60`
  - `Menu button positioned at (x, y), viewport: widthxheight`
  - `Creating settings panel...`
  - `Settings panel configured: z_index=20, visible=false`
  - `Settings panel positioned at (x, y), size: 300x350`

- **🔴 Red (Rot)**: Fehler / Errors
  - `ERROR: menu_button is null in _update_button_position`
  - `Player not found or method missing!`

## Bedienung / Controls

### Debug Overlay Controls:
- **📋 Button**: Toggle Debug-Panel Ein/Aus / Toggle debug panel on/off
- **🗑 Button**: Lösche alle Logs / Clear all logs

### Game Controls:
- **Joystick** (unten links): Bewegung / Movement
- **☰ Menu Button** (unten rechts): Öffnet Settings / Opens settings
- **🐛 Button** (oben rechts): Narrative Debug Info

## Typische Debug-Szenarien / Typical Debug Scenarios

### Szenario 1: Menu Button nicht sichtbar / Menu Button Not Visible

**Was zu suchen ist / What to look for:**
```
✅ [0.17s] Menu button added to scene tree, visible=true
✅ [0.18s] Menu button positioned at (1080, 870), viewport: 1200x960
```

**Problem identifizieren / Identify problem:**
- Position außerhalb Bildschirm? / Position outside screen?
  - `positioned at (1300, 870)` bei viewport `1200x960` → Button ist rechts außerhalb!
  - `positioned at (1300, 870)` with viewport `1200x960` → Button is outside right!

- Button wurde nicht erstellt? / Button not created?
  - ❌ Fehlt: `Menu button added to scene tree`
  - ❌ Missing: `Menu button added to scene tree`

### Szenario 2: Settings Panel öffnet nicht / Settings Panel Won't Open

**Was zu suchen ist / What to look for:**
```
✅ [0.21s] Settings panel added to scene tree
❌ Fehlt: Menu button pressed! (Button funktioniert nicht)
```

**Problem identifizieren / Identify problem:**
- Button-Event wird nicht ausgelöst / Button event not triggered
  - z-index zu niedrig? / z-index too low?
  - mouse_filter falsch? / mouse_filter wrong?
  
- Panel öffnet, aber ist nicht sichtbar / Panel opens but not visible:
  ```
  ✅ [2.45s] Menu button pressed!
  ✅ [2.46s] Settings panel visibility toggled to: true
  ✅ [2.47s] Settings panel positioned at (450, 440), size: 300x350
  ```
  → Panel sollte bei (450, 440) sichtbar sein / Panel should be visible at (450, 440)

### Szenario 3: Camera Toggle funktioniert nicht / Camera Toggle Not Working

**Was zu suchen ist / What to look for:**
```
✅ [5.12s] Camera toggle pressed
❌ [5.13s] Player not found or method missing!
```

**Problem identifizieren / Identify problem:**
- Player-Referenz fehlt beim Start / Player reference missing at startup:
  ```
  ❌ [0.13s] Player reference: NOT FOUND
  ```

## Integration in Bestehende Systeme / Integration with Existing Systems

Das Debug-Overlay arbeitet zusammen mit:
The debug overlay works together with:

1. **UIManager** (`ui_manager.gd`)
   - Zeigt Status-Nachrichten / Shows status messages
   - Debug-Overlay stört nicht / Debug overlay doesn't interfere

2. **DebugNarrativeUI** (`debug_narrative_ui.gd`)
   - 🐛 Button oben rechts / 🐛 button top right
   - Debug-Overlay oben links / Debug overlay top left
   - Keine Überlappung / No overlap

3. **MobileControls** (`mobile_controls.gd`)
   - Joystick unten links / Joystick bottom left
   - Menu Button unten rechts / Menu button bottom right
   - Debug-Overlay stört nicht / Debug overlay doesn't interfere

## Performance-Hinweise / Performance Notes

- **Auto-Trimming**: Nur 50 Zeilen werden gespeichert / Only 50 lines are stored
- **Console Fallback**: Logs gehen auch in Console (für Entwicklung) / Logs also go to console (for development)
- **Z-Index**: Sehr hoch (100/99) für maximale Sichtbarkeit / Very high (100/99) for maximum visibility
- **Transparent**: 75% Transparenz ermöglicht Spielsicht / 75% transparency allows game view

## Nächste Schritte nach dem Debugging / Next Steps After Debugging

1. **Identifiziere das Problem** in den Logs / Identify the problem in logs
2. **Behebe die Ursache** im entsprechenden Script / Fix the cause in appropriate script
3. **Teste erneut** mit Debug-Overlay / Test again with debug overlay
4. **Entferne oder deaktiviere** Debug-Logs nach Fehlerbehebung / Remove or disable debug logs after fixing

## Beispiel-Workflow / Example Workflow

```
1. Spiel starten / Start game
   → Debug-Panel erscheint automatisch / Debug panel appears automatically

2. Logs überprüfen / Check logs
   → Alle MobileControls._ready() Nachrichten sichtbar / All MobileControls._ready() messages visible

3. Menu Button testen / Test menu button
   → Tippe auf ☰ / Tap ☰
   → Suche: "Menu button pressed!" / Look for: "Menu button pressed!"

4. Settings Panel prüfen / Check settings panel
   → Suche: "Settings panel visibility toggled to: true"
   → Panel sollte erscheinen / Panel should appear

5. Camera Toggle testen / Test camera toggle
   → Tippe auf "👁 Toggle First Person View"
   → Suche: "Camera view toggled to: First Person"

6. Problem gefunden? / Found problem?
   → Schau auf Position, z-index, visible Status
   → Look at position, z-index, visible status
```
