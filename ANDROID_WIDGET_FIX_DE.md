# Android Widget Problem - Lösung (German)

## Problem
"ich kann mit dem gebauten APK immernoch kein widget erstellen auf dem Handy"

## Ursache
Das Android Widget konnte nicht auf dem Handy erstellt werden, weil der Gradle Build in `export_presets.cfg` deaktiviert war (`gradle_build/use_gradle_build=false`).

Wenn der Gradle Build deaktiviert ist, werden Android Plugins nicht in die APK eingebaut, auch wenn der Code vorhanden ist.

## Lösung
Die Konfiguration wurde geändert:

**Datei: `export_presets.cfg`**
```
- gradle_build/use_gradle_build=false
+ gradle_build/use_gradle_build=true
```

## Wichtig: Android Build Template erforderlich

Bevor die APK gebaut werden kann, muss das Android Build Template einmalig installiert werden:

1. Projekt in Godot Editor öffnen
2. **Project → Install Android Build Template** auswählen
3. Dies erstellt das `android/build/` Verzeichnis
4. Danach kann die APK gebaut werden

```bash
./build.sh
```

## Widget verwenden

Nach dem Neubauen der APK:

1. APK auf dem Handy installieren
2. Spiel mindestens einmal starten und speichern
3. Auf dem Home-Screen lange drücken
4. **"Widgets"** auswählen
5. **"YouGame Save Status"** finden und auf den Home-Screen ziehen

Das Widget zeigt dann:
- Letzter Speicherzeitpunkt
- Tag-Nummer
- Gesundheit (%)
- Anzahl Fackeln
- Position (X, Z Koordinaten)

## Technische Details

Das Widget-Plugin liegt in `android/plugins/savegame_widget/` und enthält:
- Java-Code für das Android Widget
- Layout-Dateien für die Anzeige
- Konfigurationsdateien (.gdap, AndroidManifest.xml)

Mit aktiviertem Gradle Build wird das Plugin automatisch in die APK eingebaut und das Widget erscheint in der Android Widget-Liste.

## Änderungen

- `export_presets.cfg`: Gradle Build aktiviert (1 Zeile geändert)
- `DEVELOPMENT.md`: Dokumentation ergänzt mit Build Template Anforderung

## Sicherheit

✅ Code Review: Keine Probleme
✅ CodeQL Security Scan: Keine Sicherheitslücken
✅ Minimale Änderung: Nur Konfiguration, kein neuer Code

---

**Status**: ✅ Behoben  
**Datum**: 2026-01-22
