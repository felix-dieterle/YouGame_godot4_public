# Animierte Figuren - Visuelle Übersicht

## Wo erscheinen die animierten Figuren?

### 1. Am Startpunkt (Starting Location)
```
     Markierungsstein
         |
    [ * Character ]
   /                \
[ * ]              [ * ]
  Charaktere um den zentralen Marker herum
  (3 Figuren im Kreis angeordnet)
```

**Position**: 
- 3 Charaktere platziert in einem Kreis um den zentralen Steinmarker
- Abstand: ~5-7 Einheiten vom Zentrum
- Rotation: Zufällig verteilt um 360°

**Verhalten**:
- Manche stehen still (Idle-Animation)
- Manche gehen langsam in einem kleinen Radius herum (Walk-Animation)

---

### 2. Bei Häusern (Siedlungen)
```
    🏠 Haus
    |
    |  ~3 Meter
    |
    [ * Character ]
    
    Chance: 30% pro Haus
    Max: 3 Charaktere pro Chunk
```

**Position**:
- 2-4 Einheiten Abstand vom Gebäude
- Zufälliger Winkel (kann an jeder Seite des Gebäudes sein)
- Nur auf begehbarem Terrain

**Verhalten**:
- Erscheinen bei ~30% der Gebäude
- Maximum 3 Charaktere pro Siedlungs-Chunk (verhindert Überfüllung)
- Bleiben in der Nähe ihres Startpunkts

---

### 3. Bei Leuchttürmen (Küstengebiete)
```
         🗼 Leuchtturm
          |
    Leuchtfeuer 🔆
          |
    [ * Character ]
    
    Chance: 80% pro Leuchtturm
```

**Position**:
- 2-4 Einheiten Abstand vom Leuchtturm
- Zufällige Position um den Leuchtturm herum
- Auf Küstenterrain (Land, nicht Wasser)

**Verhalten**:
- Hohe Wahrscheinlichkeit (80%), da Leuchttürme selten sind
- Einzelne Charaktere pro Leuchtturm
- Können den Leuchtturm "bewachen" oder beobachten

---

## Charakteranimationen

Die Charaktere nutzen die **Universal Animation Library** mit folgenden Zuständen:

### IDLE (Stehend)
- Charakter steht an Ort und Stelle
- Spielt Idle/Stand-Animation aus der GLB-Datei
- Dauer: ~5 Sekunden
- Dann 30% Chance zum Wechsel in WALKING

### WALKING (Gehend)
- Charakter bewegt sich langsam
- Bleibt innerhalb von 3 Einheiten vom Startpunkt
- Spielt Walk/Run-Animation aus der GLB-Datei
- Dauer: ~3 Sekunden
- Kehrt dann zu IDLE zurück

---

## Technische Details

### Modelldatei
- **Datei**: `assets/animations/character_animations.glb`
- **Lizenz**: CC0 1.0 (Public Domain)
- **Quelle**: Universal Animation Library von Quaternius
- **Größe**: ~7.8 MB

### Animation-Auswahl
Das System sucht automatisch nach passenden Animationen:
- IDLE: Sucht nach "idle", "stand"
- WALK: Sucht nach "walk", "run"
- Fallback: Verwendet erste verfügbare Animation

### Terrain-Anpassung
- Charaktere werden automatisch an die Terrainhöhe angepasst
- Nur auf begehbarem Terrain platziert (Steigung < 30°)
- Vermeidet Seen, Ozeane und steile Hänge

---

## Beispiel-Szenarien

### Szenario 1: Neues Spiel starten
1. Spieler spawnt am Startpunkt (0, 0, 0)
2. Sieht sofort 3 animierte Figuren um den zentralen Marker
3. Einige stehen, andere gehen langsam herum
4. Charaktere bleiben in der Nähe des Startbereichs

### Szenario 2: Siedlung entdecken
1. Spieler erreicht einen Cluster mit ~9 Häusern
2. Bei ~3 der Häuser (30% von 9) stehen Charaktere
3. Charaktere können vor, hinter oder neben den Häusern sein
4. Gibt der Siedlung ein "bewohntes" Gefühl

### Szenario 3: Leuchtturm finden
1. Spieler reist zur Küste
2. Findet einen Leuchtturm mit leuchtendem Beacon
3. Mit 80% Wahrscheinlichkeit steht ein Charakter beim Leuchtturm
4. Charakter könnte der "Leuchtturmwärter" sein

---

## Performance

### Optimierungen
- Charaktere werden nur in geladenen Chunks generiert
- Shared GLB-Modelldaten (eine Datei für alle Charaktere)
- Limitierung: Max 3 Charaktere pro Siedlungs-Chunk
- Lighthouses sind selten, daher wenige Charaktere gesamt

### Geschätzte Anzahl
Bei typischem Gameplay:
- Startbereich: 3 Charaktere (fest)
- Pro Siedlung: 0-3 Charaktere (Durchschnitt ~1)
- Pro Leuchtturm: 0-1 Charakter (meistens 1)
- **Gesamt sichtbar**: ~5-15 Charaktere gleichzeitig

---

## Zukünftige Verbesserungen

Mögliche Erweiterungen:
1. **Mehr Animationen**: Nutze mehr Animationen aus der UAL
   - Sitting (Sitzen)
   - Working (Arbeiten)
   - Waving (Winken zum Spieler)

2. **Charaktervariationen**: 
   - Verschiedene Farben/Materialien
   - Unterschiedliche Größen
   - Verschiedene Modelle aus der Bibliothek

3. **Interaktivität**:
   - Dialog-System
   - Quest-Geber
   - Händler

4. **Zeitbasiertes Verhalten**:
   - Charaktere gehen nachts schlafen
   - Tagsüber mehr Aktivität
   - Unterschiedliche Positionen zu verschiedenen Zeiten

5. **Soziales Verhalten**:
   - Charaktere unterhalten sich miteinander
   - Gruppen von Charakteren
   - Familien in Häusern
