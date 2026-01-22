# Fischerboot Implementierung

## Zusammenfassung

Dieses Feature fügt ein einfaches Fischerboot hinzu, das am Ufer der ersten generierten Meeresbereich halb im Sand liegt. Das Boot erscheint auf Küsten-Chunks in der Nähe des Startpunkts (0,0) und ist realistisch im Sand vergraben.

## Implementierte Features

### Fischerboot System
- **Prozedurale Generierung**: Einfaches Low-Poly-Fischerboot aus verwittertem Holz
- **Küstenplatzierung**: Boot wird automatisch auf Küsten-Chunks in der Nähe des Startbereichs platziert
- **Realistische Positionierung**: 
  - Boot ist 30% im Sand vergraben für natürlichen gestrandeten Look
  - Boot zeigt in Richtung Ozean
  - Leichte zufällige Neigung für natürliches Aussehen
- **Einmalige Platzierung**: Nur ein Boot pro Spiel, deterministisch platziert

### Boot-Design
- **Abmessungen**: 
  - Länge: 4.0 Einheiten
  - Breite: 1.5 Einheiten
  - Höhe: 0.8 Einheiten
- **Merkmale**:
  - Spitze Vorderseite (Bug)
  - Abgeschrägte Seiten
  - Flacher Boden (für Strand)
  - Einfache Sitzbank im Inneren
  - Verwitterte Holzfarbe (braun)

### Technische Details

#### Neue Konstanten in `chunk.gd`:
```gdscript
const FISHING_BOAT_SEED_OFFSET = 88888           # Seed-Offset für Boot-Platzierung
const FISHING_BOAT_PLACEMENT_RADIUS = 96.0       # Platzierung innerhalb 3 Chunks vom Start
```

#### Neue Konstanten in `procedural_models.gd`:
```gdscript
const BOAT_LENGTH = 4.0      # Boot-Länge
const BOAT_WIDTH = 1.5       # Boot-Breite
const BOAT_HEIGHT = 0.8      # Boot-Höhe
const BOAT_SEGMENTS = 8      # Mesh-Segmente
```

#### Neue Funktionen:

**In `procedural_models.gd`:**
- `create_fishing_boat_mesh(seed_val)` - Erstellt prozedurales Boot-Mesh
- `create_fishing_boat_material()` - Erstellt verwittertes Holz-Material

**In `chunk.gd`:**
- `_place_fishing_boat_if_coastal()` - Hauptfunktion für Boot-Platzierung
- `_find_coastal_boat_position(rng, ocean_direction)` - Findet geeignete Position am Strand
- `_place_fishing_boat(pos, rng, ocean_direction)` - Platziert und konfiguriert Boot

## Verwendung

Das Fischerboot-System ist vollständig in die Chunk-basierte Weltgenerierung integriert:

```gdscript
# Boot wird automatisch auf passenden Küsten-Chunks platziert
var chunk = Chunk.new(1, 0, 12345)
chunk.generate()

if chunk.placed_fishing_boat:
    print("Fischerboot platziert!")
    print("Position: ", chunk.placed_fishing_boat.position)
```

## Generierungspipeline

Die erweiterte Chunk-Generierung:

1. Heightmap-Generierung
2. Begehbarkeitsberechnung
3. Metadaten-Berechnung → Ozean-Biom-Erkennung
4. See-Generierung (Täler)
5. Ozean-Generierung
6. Mesh-Erstellung
7. Objekt-Platzierung (Steine, Bäume, Gebäude)
8. Pfad-Generierung
9. Leuchtturm-Platzierung
10. **Fischerboot-Platzierung** → Neu

## Platzierungslogik

Das Boot wird platziert wenn:
1. Der Chunk KEIN Ozean ist
2. Der Chunk mindestens einen benachbarten Ozean-Chunk hat (Nord, Süd, Ost oder West)
3. Der Chunk innerhalb von 96 Einheiten (3 Chunks) vom Startpunkt (0,0) ist
4. Der Chunk durch deterministische Hash-Funktion ausgewählt wird (nur ein Boot pro Spiel)

Das Boot wird positioniert:
- Nahe der Kante zum Ozean
- 30% im Sand vergraben (y-Position reduziert)
- Zeigt in Richtung des Ozeans
- Mit leichter zufälliger Neigung (x: ±0.05, z: ±0.1 Radiant)

## Performance

- **Boot-Mesh**: Einfaches Low-Poly-Mesh (~150 Vertices), minimaler Overhead
- **Platzierung**: Nur ein Boot pro Spiel, vernachlässigbarer Performance-Einfluss
- **Küstenerkennung**: Effiziente Höhenschätzung wie beim Leuchtturm-System

## Tests

Zwei Testsuiten verifizieren das Fischerboot-System:

### Unit Test (`test_fishing_boat.gd`)
- Verifiziert Boot-Mesh/Material-Erstellung
- Testet Boot-Platzierung auf Küsten-Chunks
- Validiert Boot-Konstanten

### Visueller Test (`test_fishing_boat_visual.gd`)
- Erstellt ein 5×5-Raster von Chunks
- Erfasst Screenshots vom Boot am Strand
- Berichtet Statistiken über Boot-Platzierung

Tests ausführen:
```bash
./run_tests.sh
# oder
godot --headless res://tests/test_scene_fishing_boat.tscn
godot --headless res://tests/test_scene_fishing_boat_visual.tscn
```

## Konfiguration

Boot-Generierung anpassen durch Ändern der Konstanten:

- **Platzierungs-Radius**: `FISHING_BOAT_PLACEMENT_RADIUS` ändern für größere/kleinere Suchbereich
- **Boot-Größe**: Konstanten in `procedural_models.gd` für Größe/Proportionen bearbeiten
- **Vergrabungs-Tiefe**: In `_place_fishing_boat()` die `burial_depth` Berechnung anpassen
- **Auswahl-Hash**: Modulo-Wert in `_place_fishing_boat_if_coastal()` ändern für andere Platzierung

## Zukünftige Verbesserungen

Mögliche Erweiterungen:
- Mehrere Boot-Varianten (Ruderboot, Segelboot)
- Zusätzliche Details (Ruder, Segel, Netze)
- Interaktivität (Boot betreten, reparieren)
- Weitere Strand-Objekte (Anker, Fässer, Kisten)
- Animation (leichte Bewegung bei Wind)
- Fischernetze oder Ausrüstung am Strand

## Integration mit bestehenden Systemen

Das Fischerboot-System integriert sich nahtlos mit:
- **Ozean-System**: Nutzt Ozean-Erkennungslogik zur Küstenerkennung
- **Chunk-System**: Folgt gleicher Generierungspipeline wie andere Objekte
- **Narrative Marker**: Könnte als Questziel oder Entdeckungspunkt dienen
- **Cluster-System**: Respektiert existierende Objekt-Platzierungen

## Dokumentation

Verwandte Dokumentation:
- [OZEAN_LEUCHTTURM_ZUSAMMENFASSUNG.md](OZEAN_LEUCHTTURM_ZUSAMMENFASSUNG.md) - Ozean und Leuchtturm System
- [FEATURES.md](FEATURES.md) - Feature-Übersicht
- [README.md](README.md) - Projekt-Übersicht
