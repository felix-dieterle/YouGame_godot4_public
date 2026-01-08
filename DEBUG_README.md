# Debug Overlay System - Quick Reference

## 🎯 Zweck / Purpose

**Deutsch:** Transparentes Debug-System zur Diagnose von UI-Problemen (Settings Panel und First-Person Toggle).

**English:** Transparent debug system to diagnose UI issues (Settings Panel and First-Person Toggle).

## 🚀 Schnellstart / Quick Start

### Spiel starten / Start Game
```bash
# Desktop
godot --path . scenes/main.tscn

# Android Build
./build.sh
adb install export/YouGame.apk
```

### Was Sie sehen / What You'll See

```
┌────────────────────────────────┐
│ 📋 🗑         Debug Logs       │
│ ┌──────────────────────────┐  │
│ │ [0.05s] System Started   │  │
│ │ [0.12s] Controls ready   │  │
│ │ [0.17s] Menu button OK   │  │
│ │ [2.45s] Button pressed!  │  │
│ └──────────────────────────┘  │
│          GAME VIEW             │
│                                │
│  (o)                      ☰   │
└────────────────────────────────┘
```

## 📚 Dokumentation / Documentation

| Datei / File | Beschreibung / Description |
|--------------|----------------------------|
| **DEBUGGING_ANLEITUNG.md** | ⭐ **START HERE** - Schritt-für-Schritt Anleitung / Step-by-step guide |
| **DEBUG_OVERLAY_VISUAL_GUIDE.md** | Visuelle Beispiele / Visual examples |
| **DEBUG_OVERLAY_SYSTEM.md** | Technische Details / Technical details |
| **IMPLEMENTATION_DEBUG_OVERLAY.md** | Vollständige Zusammenfassung / Complete summary |

## 🔍 Häufige Probleme / Common Issues

### Menu Button nicht sichtbar / Menu Button Not Visible
```
Suchen Sie nach / Look for:
✅ Menu button added to scene tree, visible=true
✅ Menu button positioned at (X, Y)

Problem: Position außerhalb Bildschirm? / Position outside screen?
```

### Settings Panel öffnet nicht / Settings Panel Won't Open
```
Suchen Sie nach / Look for:
❌ Fehlt: "Menu button pressed!" 
→ Button empfängt keine Klicks / Button not receiving clicks
```

### Camera Toggle funktioniert nicht / Camera Toggle Not Working
```
Suchen Sie nach / Look for:
❌ Player reference: NOT FOUND
→ Player-Node fehlt / Player node missing
```

## 🎨 Farben / Colors

- 🟢 **Grün/Green** → Erfolg / Success
- 🟡 **Gelb/Yellow** → Ereignisse / Events  
- 🔵 **Cyan** → Info / Information
- 🔴 **Rot/Red** → Fehler / Errors

## 🛠️ Bedienung / Controls

- **📋** → Logs ein/aus / Toggle logs
- **🗑** → Logs löschen / Clear logs

## 📝 Beispiel-Logs / Example Logs

```
[0.05s] === Debug Log System Started ===
[0.12s] MobileControls._ready() started
[0.13s] Player reference: Found
[0.17s] Menu button added to scene tree, visible=true
[0.18s] Menu button positioned at (1080, 870), viewport: 1200x960
[2.45s] Menu button pressed!
[2.46s] Settings panel visibility toggled to: true
```

## 🔗 Nächste Schritte / Next Steps

1. **Lesen Sie** / Read: `DEBUGGING_ANLEITUNG.md`
2. **Starten Sie** das Spiel / Start the game
3. **Überprüfen Sie** die Logs / Check the logs
4. **Identifizieren Sie** das Problem / Identify the problem
5. **Beheben Sie** den Fehler / Fix the issue

## 📞 Hilfe / Help

Bei Fragen öffnen Sie ein Issue mit:
For questions, open an issue with:
- Screenshot der Debug-Logs / Screenshot of debug logs
- Geräteinformationen / Device information
- Schritte zur Reproduktion / Steps to reproduce

---

**Tipp:** Beginnen Sie mit `DEBUGGING_ANLEITUNG.md` für eine vollständige Anleitung!

**Tip:** Start with `DEBUGGING_ANLEITUNG.md` for a complete guide!
