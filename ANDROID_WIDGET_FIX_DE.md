# Android Widget - Aktivierungsanleitung (German)

## Problem
"ich kann mit dem gebauten APK immernoch kein widget erstellen auf dem Handy"

## Ursache
Das Android Widget ist im Code vorhanden, wird aber standardmäßig nicht in die APK eingebaut. Das Widget erfordert:
1. Android Build Template Installation (über Godot Editor)
2. Gradle Build Aktivierung in `export_presets.cfg`

Diese Schritte können nicht in CI/CD automatisiert werden, da das Android Build Template nur durch den Godot Editor installiert werden kann und nicht committet werden sollte.

## Lösung: Lokales Build mit Widget

Um eine APK mit Widget zu erstellen, muss lokal gebaut werden:

### Schritt 1: Android Build Template installieren

1. Projekt in Godot Editor öffnen
2. **Project → Install Android Build Template** auswählen
3. Dies erstellt das `android/build/` Verzeichnis
4. Diese Dateien **nicht** ins Git committen (sind in `.gitignore`)

### Schritt 2: Gradle Build aktivieren

Bearbeite die Datei `export_presets.cfg`:

**Datei: `export_presets.cfg` (Zeile 21)**
```
- gradle_build/use_gradle_build=false
+ gradle_build/use_gradle_build=true
```

**Wichtig:** Diese Änderung **nicht** committen, da sie den CI/CD Build brechen würde.

### Schritt 3: APK bauen

```bash
./build.sh
```

Oder im Godot Editor: **Project → Export → Android → Export Project**

## Technische Details

### Widget-Plugin

Das Widget-Plugin liegt in `android/plugins/savegame_widget/` und enthält:
- Java-Code für das Android Widget
- Layout-Dateien für die Anzeige
- Konfigurationsdateien (.gdap, AndroidManifest.xml)
- Pre-built AAR Datei (savegame_widget.aar)

Mit aktiviertem Gradle Build wird das Plugin automatisch in die APK eingebaut und das Widget erscheint in der Android Widget-Liste.

## Warum nicht in CI/CD?

Das Widget kann nicht in CI/CD automatisch gebaut werden, weil:

1. **Android Build Template kann nicht programmatisch installiert werden**
   - Muss durch Godot Editor installiert werden
   - Keine Kommandozeilen-Option verfügbar
   - Headless-Modus unterstützt Installation nicht

2. **Build Template sollte nicht committet werden**
   - Enthält projektspezifische Build-Dateien
   - Wird für jedes Projekt neu generiert
   - Best Practice: Nicht ins Repository committen

3. **Gradle Build erfordert Build Template**
   - Ohne installiertes Template schlägt Gradle Export fehl
   - Keine Workaround-Möglichkeit in Godot 4.3
   - Widget-Plugin benötigt Gradle Build

## Alternative: Lokales Build

Für Nutzer, die das Widget nutzen möchten:
- Folge den Schritten oben für lokales Build
- Oder warte auf zukünftige Godot-Versionen, die vielleicht CI-Support bieten

## Änderungen in diesem PR

- `.github/workflows/build.yml`: Widget-Build Job entfernt (CI-Inkompatibilität)
- `DEVELOPMENT.md`: Dokumentation für lokales Widget-Build
- `ANDROID_WIDGET_FIX_DE.md`: Diese Anleitung mit lokalem Build-Prozess

**Widget muss lokal gebaut werden** - CI/CD-Build ist aufgrund Godot-Einschränkungen nicht möglich.

---

**Status**: ✅ Dokumentiert  
**Datum**: 2026-01-23  
**Lösung**: Lokales Build erforderlich - Widget kann nicht in CI/CD gebaut werden
