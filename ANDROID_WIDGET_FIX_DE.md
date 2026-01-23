# Android Widget - Verfügbarkeit und Nutzung (German)

## Problem
"ich kann mit dem gebauten APK immernoch kein widget erstellen auf dem Handy"

## Lösung: Zwei APK-Versionen verfügbar

Ab sofort werden bei jedem Release **zwei APK-Versionen** automatisch gebaut:

### 1. YouGame-vX.X.X.apk (Standard-Version)
- **Ohne** Widget-Feature
- Kleinere APK-Größe
- Empfohlen für die meisten Nutzer
- Standard Android Build

### 2. YouGame-Widget-vX.X.X.apk (Widget-Version)
- **Mit** Android Home Screen Widget
- Zeigt Spielstand-Informationen auf dem Homescreen
- Etwas größere APK-Größe durch Widget-Komponenten
- Vollständig funktionsfähiges Widget

## Widget verwenden (Widget-Version)

Nach Installation der **Widget-Version** (YouGame-Widget-vX.X.X.apk):

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

## Download

Beide APK-Versionen sind in jedem GitHub Release verfügbar:
- Standard-Version für normale Nutzung
- Widget-Version für Nutzer, die das Widget nutzen möchten

**Keine manuelle Konfiguration mehr nötig!**

## Technische Details

### Automatischer Build (CI/CD)

Die CI/CD Pipeline baut automatisch beide Versionen:

1. **Standard Build Job**
   - Verwendet Standard-Konfiguration (`gradle_build=false`)
   - Baut APK ohne Widget
   - Schneller Build, kleinere APK

2. **Widget Build Job** (parallel)
   - Installiert Android Build Template programmatisch
   - Aktiviert Gradle Build temporär
   - Baut APK mit Widget
   - Beide Jobs laufen parallel für schnellere Builds

3. **Release Job** (nach Merge zu main)
   - Baut beide APK-Versionen mit aktueller Version
   - Erstellt GitHub Release mit beiden APKs
   - Nutzer können wählen, welche Version sie herunterladen

### Widget-Plugin Details

Das Widget-Plugin liegt in `android/plugins/savegame_widget/` und enthält:
- Java-Code für das Android Widget
- Layout-Dateien für die Anzeige
- Konfigurationsdateien (.gdap, AndroidManifest.xml)
- Pre-built AAR Datei (savegame_widget.aar)

Mit aktiviertem Gradle Build wird das Plugin automatisch in die APK eingebaut und das Widget erscheint in der Android Widget-Liste.

## Warum zwei separate APK-Versionen?

Statt das Widget standardmäßig zu aktivieren, bieten wir zwei APKs an, weil:

1. **Benutzerfreundlichkeit**
   - Keine manuelle Konfiguration nötig
   - Klare Wahl zwischen Standard und Widget
   - Beide Versionen sofort downloadbar

2. **CI/CD Kompatibilität**
   - Standard-Build bleibt kompatibel ohne Änderungen
   - Widget-Build nutzt spezielle CI-Konfiguration
   - Beide Builds laufen parallel (schneller)

3. **Flexibilität**
   - Nicht jeder Nutzer braucht das Widget
   - Kleinere APK für Nutzer ohne Widget-Bedarf
   - Widget-Nutzer bekommen volle Funktionalität

---

## Für Entwickler: Lokales Widget-Build (Optional)

Falls du lokal eine APK mit Widget bauen möchtest:

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

---

## Änderungen in diesem PR

- `.github/workflows/build.yml`: Paralleler Widget-Build Job hinzugefügt
- `DEVELOPMENT.md`: Erweiterte Dokumentation mit Widget-Aktivierungsanleitung
- `ANDROID_WIDGET_FIX_DE.md`: Diese Anleitung mit Dual-APK-Strategie

**Zwei APK-Versionen** - Standard und Widget werden automatisch gebaut und in Releases bereitgestellt.

---

**Status**: ✅ Implementiert  
**Datum**: 2026-01-23  
**Lösung**: Dual APK Build - Nutzer können zwischen Standard- und Widget-Version wählen
