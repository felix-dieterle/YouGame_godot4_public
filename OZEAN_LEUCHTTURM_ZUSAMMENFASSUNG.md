# Meer und Leuchtturm Implementierung

## Zusammenfassung

Dieses Feature implementiert ein Meer (Ozean-Biom), das sich über mehrere Chunks erstreckt, mit Leuchttürmen in regelmäßigen Abständen entlang der Küste.

## Implementierte Features

### Ozean/Meer System
- **Automatische Erkennung**: Chunks mit durchschnittlicher Höhe ≤ -8.0 werden als Ozean klassifiziert
- **Mehrere Chunks**: Ozeane können sich über viele angrenzende Chunks erstrecken und große Meere bilden
- **Visuelle Darstellung**: Tiefblaues, halbtransparentes Wasser mit sandigem Meeresboden
- **Wasseroberfläche**: Vollständige Chunk-Abdeckung mit glatten, reflektierenden Wasserflächen

### Leuchtturm System
- **Küstenplatzierung**: Leuchttürme werden automatisch auf Küsten-Chunks platziert (Land-Chunks neben Ozean)
- **Regelmäßige Abstände**: Leuchttürme erscheinen alle ~80 Welteinheiten entlang der Küstenlinie
- **Charakteristisches Design**:
  - 8 Einheiten hoher Turm mit rot-weißen Streifen
  - Leuchtfeuer-Plattform und Lichtgehäuse
  - Rotes konisches Dach
  - Warmes gelbes Licht mit 30 Einheiten Sichtweite

### Technische Details

#### Neue Konstanten in `chunk.gd`:
```gdscript
const OCEAN_LEVEL = -8.0              # Höhenschwelle für Ozean-Biom
const LIGHTHOUSE_SPACING = 80.0        # Abstand zwischen Leuchttürmen
const LIGHTHOUSE_SEED_OFFSET = 77777   # Seed-Offset für Leuchtturm-Platzierung
```

#### Neue Konstanten in `procedural_models.gd`:
```gdscript
const LIGHTHOUSE_TOWER_HEIGHT = 8.0       # Turmhöhe
const LIGHTHOUSE_TOWER_RADIUS = 0.8       # Turmradius
const LIGHTHOUSE_TOWER_SEGMENTS = 8       # Zylindersegmente
const LIGHTHOUSE_BEACON_HEIGHT = 1.5      # Höhe des Leuchtfeuergehäuses
const LIGHTHOUSE_BEACON_RADIUS = 1.2      # Radius der Leuchtfeuerplattform
```

## Verwendung

Das Ozean- und Leuchtturm-System ist vollständig in die Chunk-basierte Weltgenerierung integriert:

```gdscript
# Ozean-Chunks werden automatisch basierend auf der Höhe erkannt
var chunk = Chunk.new(-5, -5, 12345)
chunk.generate()

if chunk.is_ocean:
    print("Ozean-Chunk mit Wassermesh erstellt")
    
if chunk.placed_lighthouses.size() > 0:
    print("Küsten-Chunk mit %d Leuchttürmen" % chunk.placed_lighthouses.size())
```

## Generierungspipeline

Die erweiterte Chunk-Generierung:

1. Heightmap-Generierung
2. Begehbarkeitsberechnung
3. Metadaten-Berechnung → **Ozean-Biom-Erkennung**
4. See-Generierung (Täler)
5. **Ozean-Generierung** → Neu
6. Mesh-Erstellung (mit Meeresboden-Färbung)
7. Objekt-Platzierung (Steine, Bäume, Gebäude)
8. Pfad-Generierung
9. **Leuchtturm-Platzierung** → Neu

## Küstenerkennung

Leuchttürme werden auf Chunks platziert, die:
1. Selbst KEIN Ozean sind
2. Mindestens einen benachbarten Ozean-Chunk haben (Nord, Süd, Ost oder West)
3. Auf dem Leuchtturm-Raster positioniert sind (alle `LIGHTHOUSE_SPACING` Einheiten)

## Performance

- **Ozean-Wasser**: Einfaches Quad-Mesh pro Chunk (2 Dreiecke), minimaler Overhead
- **Leuchttürme**: Sparsame Platzierung auf Rastermuster, nicht auf jedem Küsten-Chunk
- **Küstenerkennung**: Effiziente Höhenschätzung der Nachbarn ohne vollständige Generierung
- **Lichtanzahl**: Durch Abstandsbeschränkungen begrenzt, um zu viele dynamische Lichter zu vermeiden

## Tests

Zwei Testsuiten verifizieren das Ozean- und Leuchtturm-System:

### Unit Test (`test_ocean_lighthouse.gd`)
- Verifiziert Leuchtturm-Mesh/Material-Erstellung
- Testet Ozean-Chunk-Erkennung
- Validiert Küsten-Chunk-Leuchtturm-Platzierung

### Visueller Test (`test_ocean_visual.gd`)
- Erstellt ein 5×5-Raster von Chunks
- Erfasst Screenshots von Ozean und Leuchttürmen
- Berichtet Statistiken über Ozeanbedeckung und Leuchtturm-Platzierung

Tests ausführen:
```bash
./run_tests.sh
# oder
godot --headless res://tests/test_scene_ocean_lighthouse.tscn
godot --headless res://tests/test_scene_ocean_visual.tscn
```

## Konfiguration

Ozean- und Leuchtturm-Generierung anpassen durch Ändern der Konstanten:

- **Ozean-Niveau**: `OCEAN_LEVEL` ändern, um anzupassen, welche Höhe als Ozean zählt
- **Leuchtturm-Abstand**: `LIGHTHOUSE_SPACING` ändern für mehr/weniger Leuchttürme
- **Leuchtturm-Aussehen**: Konstanten in `procedural_models.gd` für Größe/Proportionen bearbeiten

## Dokumentation

Vollständige englische Dokumentation verfügbar in:
- [OCEAN_LIGHTHOUSE_SYSTEM.md](docs/systems/OCEAN_LIGHTHOUSE_SYSTEM.md)
- [FEATURES.md](FEATURES.md) - Feature-Übersicht
- [README.md](README.md) - Projekt-Übersicht

## Zukünftige Verbesserungen

Mögliche Erweiterungen:
- Animierte Wasseroberfläche (Wellen-Shader)
- Rotierendes Leuchtturm-Leuchtfeuer
- Strand-/Küstenübergangszonen
- Ozean-spezifische Features (Schiffswracks, Inseln)
- Leuchtturm-Aktivierung nur nachts
- Nebelhorn-Soundeffekte
