# Android Widget - Aktivierungsanleitung (German)

## Problem
"ich kann mit dem gebauten APK immernoch kein widget erstellen auf dem Handy"

## Ursache
Das Android Widget ist im Code vorhanden, wird aber standardmäßig nicht in die APK eingebaut. Das Widget erfordert:
1. Android Build Template Installation (über Godot Editor)
2. Gradle Build Aktivierung in `export_presets.cfg`

Beide Schritte müssen manuell durchgeführt werden, da sie nicht im Repository enthalten sein können (Build Template enthält projektspezifische Dateien, die nicht committet werden sollten).

## Lösung - Schritt für Schritt

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

## Warum nicht standardmäßig aktiviert?

Das Widget kann nicht standardmäßig aktiviert werden, weil:

1. **Android Build Template kann nicht committet werden**
   - Enthält projektspezifische Build-Dateien
   - Wird durch Godot Editor generiert
   - Muss lokal auf jedem System installiert werden

2. **CI/CD Kompatibilität**
   - GitHub Actions Build läuft im headless Modus
   - Kann kein Build Template installieren
   - Gradle Build würde den automatischen Build brechen

3. **Standard-Builds müssen funktionieren**
   - Nicht jeder Entwickler braucht das Widget
   - CI/CD muss ohne manuelle Einrichtung laufen
   - Widget ist ein optionales Feature

## Technische Details

Das Widget-Plugin liegt in `android/plugins/savegame_widget/` und enthält:
- Java-Code für das Android Widget
- Layout-Dateien für die Anzeige
- Konfigurationsdateien (.gdap, AndroidManifest.xml)
- Pre-built AAR Datei (savegame_widget.aar)

Mit aktiviertem Gradle Build wird das Plugin automatisch in die APK eingebaut und das Widget erscheint in der Android Widget-Liste.

## Änderungen in diesem PR

- `DEVELOPMENT.md`: Erweiterte Dokumentation mit Widget-Aktivierungsanleitung
- `ANDROID_WIDGET_FIX_DE.md`: Diese Anleitung auf Deutsch

**Keine Code-Änderungen** - Widget-Aktivierung erfolgt lokal durch Benutzer.

---

**Status**: ✅ Dokumentiert  
**Datum**: 2026-01-22  
**Hinweis**: Widget-Code ist vorhanden, Aktivierung erfolgt manuell durch Benutzer
