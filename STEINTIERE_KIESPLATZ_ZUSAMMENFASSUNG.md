# Steintiere Kiesplatz Implementierung

## Zusammenfassung

Dieses Feature fügt einen einmaligen Kiesplatz mit verschiedenen einfachen Steintieren hinzu. Der Kiesplatz befindet sich in begrenztem Abstand vom Startpunkt und ist mit verschiedenen Arten von abstrakten Steinskulpturen dekoriert (Vogel, Hase, Reh, Fuchs).

## Implementierte Features

### Kiesplatz System
- **Einmalige Platzierung**: Nur ein Kiesplatz im gesamten Spielwelt, deterministisch platziert
- **Begrenzte Entfernung**: Platziert in Entfernung zwischen 96-128 Einheiten vom Startpunkt (3-4 Chunks)
- **Flache Terrain-Auswahl**: System sucht automatisch nach relativ flachem Gelände
- **Kiesboden**: Dichter Boden aus vielen kleinen Kieseln/Steinchen
- **Steintiere**: 4-8 verschiedene abstrakte Steintiere im Kiesplatz

### Steintier-Typen
Das System unterstützt vier verschiedene Steintier-Arten:

1. **Vogel** (BIRD)
   - Höhe: ~0.6 Einheiten
   - Breite: ~0.4 Einheiten
   - Merkmale: Körper, Kopf, Schnabel, Flügel

2. **Hase** (RABBIT)
   - Höhe: ~0.5 Einheiten
   - Breite: ~0.4 Einheiten
   - Merkmale: Körper, Kopf, lange Ohren, Schwanz

3. **Reh** (DEER)
   - Höhe: ~1.2 Einheiten
   - Breite: ~0.7 Einheiten
   - Merkmale: Körper, Hals, Kopf, Geweih, vier Beine

4. **Fuchs** (FOX)
   - Höhe: ~0.6 Einheiten
   - Breite: ~0.5 Einheiten
   - Merkmale: Körper, Kopf, spitze Ohren, Schnauze, buschiger Schwanz

### Kiesplatz-Design
- **Radius**: 8.0 Einheiten (kreisförmiger Bereich)
- **Kiesel-Dichte**: 150 kleine Kiesel pro Kiesplatz
- **Kiesel-Größe**: 0.05-0.15 Einheiten (sehr klein)
- **Steintiere**: 4-8 Tiere, gleichmäßig verteilt
- **Farbe**: Graustein-Töne für alle Elemente

## Technische Details

### Neue Konstanten in `chunk.gd`:
```gdscript
const GRAVEL_AREA_SEED_OFFSET = 99999              # Seed-Offset für Kiesplatz-Platzierung
const GRAVEL_AREA_PLACEMENT_RADIUS = 128.0         # Platzierung innerhalb 4 Chunks vom Start
const GRAVEL_AREA_SELECTION_MODULO = 11            # Hash-Modulo für deterministische Auswahl
const GRAVEL_AREA_SELECTION_VALUE = 7              # Zielwert für Chunk-Auswahl
const GRAVEL_AREA_RADIUS = 8.0                     # Radius des Kiesplatzes
const GRAVEL_PEBBLE_DENSITY = 150                  # Anzahl der Kiesel
const STONE_ANIMAL_COUNT_MIN = 4                   # Minimum Anzahl Steintiere
const STONE_ANIMAL_COUNT_MAX = 8                   # Maximum Anzahl Steintiere
```

### Neue Konstanten in `procedural_models.gd`:
```gdscript
# Steintier-Dimensionen
const STONE_ANIMAL_BIRD_HEIGHT = 0.6
const STONE_ANIMAL_BIRD_WIDTH = 0.4
const STONE_ANIMAL_RABBIT_HEIGHT = 0.5
const STONE_ANIMAL_RABBIT_WIDTH = 0.4
const STONE_ANIMAL_DEER_HEIGHT = 1.2
const STONE_ANIMAL_DEER_WIDTH = 0.7
const STONE_ANIMAL_FOX_HEIGHT = 0.6
const STONE_ANIMAL_FOX_WIDTH = 0.5
const STONE_COLOR = Color(0.5, 0.5, 0.55)

# Kiesel-Dimensionen
const GRAVEL_PEBBLE_MIN_SIZE = 0.05
const GRAVEL_PEBBLE_MAX_SIZE = 0.15
```

### Neue Enums:
```gdscript
enum StoneAnimalType {
    BIRD = 0,
    RABBIT = 1,
    DEER = 2,
    FOX = 3
}
```

### Neue Funktionen:

**In `procedural_models.gd`:**
- `create_stone_animal_mesh(animal_type, seed_val)` - Erstellt prozedurales Steintier-Mesh
- `create_stone_animal_material()` - Erstellt Steinmaterial für Tiere
- `create_gravel_pebble_mesh(seed_val)` - Erstellt prozeduralen Kiesel
- `create_gravel_material()` - Erstellt Material für Kiesel
- `_create_stone_bird(st, rng)` - Interner Helper für Vogel-Mesh
- `_create_stone_rabbit(st, rng)` - Interner Helper für Hasen-Mesh
- `_create_stone_deer(st, rng)` - Interner Helper für Reh-Mesh
- `_create_stone_fox(st, rng)` - Interner Helper für Fuchs-Mesh

**In `chunk.gd`:**
- `_place_gravel_area_with_stone_animals()` - Hauptfunktion für Kiesplatz-Platzierung
- `_find_gravel_area_position(rng)` - Findet geeignete flache Position
- `_create_gravel_area(center_pos, rng)` - Erstellt Kiesboden
- `_place_stone_animals_in_gravel_area(center_pos, rng)` - Platziert Steintiere

## Verwendung

Das Kiesplatz-System ist vollständig in die Chunk-basierte Weltgenerierung integriert:

```gdscript
# Kiesplatz wird automatisch auf passendem Chunk platziert
var chunk = Chunk.new(3, 2, 12345)
chunk.generate()

if chunk.has_gravel_area:
    print("Kiesplatz gefunden!")
    print("Zentrum: ", chunk.gravel_area_center)
    print("Anzahl Steintiere: ", chunk.placed_stone_animals.size())
    print("Anzahl Kiesel: ", chunk.placed_gravel_pebbles.size())
```

## Generierungspipeline

Die erweiterte Chunk-Generierung:

1. Heightmap-Generierung
2. Begehbarkeitsberechnung
3. Metadaten-Berechnung
4. See-Generierung (Täler)
5. Ozean-Generierung
6. Mesh-Erstellung
7. Objekt-Platzierung (Steine, Bäume, Gebäude)
8. Pfad-Generierung
9. Leuchtturm-Platzierung
10. Fischerboot-Platzierung
11. **Kiesplatz mit Steintieren-Platzierung** → Neu

## Platzierungslogik

Der Kiesplatz wird platziert wenn:
1. Der Chunk mindestens 96 Einheiten (3 Chunks) vom Startpunkt entfernt ist
2. Der Chunk maximal 128 Einheiten (4 Chunks) vom Startpunkt entfernt ist
3. Der Chunk KEIN Ozean ist
4. Der Chunk KEINEN See hat
5. Der Chunk NICHT Teil des einmaligen Gebirges ist (zu felsig)
6. Der Chunk durch deterministische Hash-Funktion ausgewählt wird (nur ein Kiesplatz pro Spiel)

Der Kiesplatz wird positioniert:
- Auf möglichst flachem Gelände innerhalb des Chunks
- System probiert 10 Positionen und wählt die flachste
- Zentral genug, um vollständig innerhalb des Chunks zu liegen
- Mit 8.0 Einheiten Radius kreisförmig

### Steintier-Platzierung
- 4-8 Tiere werden im Kiesplatz verteilt
- Verschiedene Tierarten wechseln sich ab für Vielfalt
- Tiere werden näher am Zentrum platziert (70% des Radius)
- Zufällige Drehung für natürliches Aussehen
- Werfen Schatten für mehr Realismus

### Kiesel-Platzierung
- 150 kleine Kiesel füllen den gesamten Kiesplatz
- Gleichmäßige Verteilung über den 8.0-Einheiten-Radius
- Zufällige Größen und leichte Farbvariationen
- Keine Schatten (zu klein für Schatten)

## Performance

- **Kiesel-Meshes**: Sehr einfache Box-Meshes (~24 Vertices pro Kiesel)
- **Steintier-Meshes**: Einfache Low-Poly-Meshes (~100-200 Vertices pro Tier)
- **Platzierung**: Nur ein Kiesplatz pro Spiel, minimaler Performance-Einfluss
- **Gesamtobjekte**: ~150 Kiesel + 4-8 Tiere = ~160 Objekte in einem Chunk
- **Schattenwurf**: Nur Steintiere werfen Schatten, nicht die kleinen Kiesel

## Designentscheidungen

### Warum abstrakte geometrische Formen?
- Mobile-Optimierung: Einfache Boxen sind performant
- Keine externen Assets: Vollständig prozedural generiert
- Künstlerische Stilisierung: Passt zum Low-Poly-Stil des Spiels
- Erkennbarkeit: Trotz Einfachheit klar als Tiere erkennbar

### Warum begrenzte Entfernung?
- Frühe Entdeckung: Spieler findet Feature innerhalb der ersten Spielminuten
- Nicht direkt am Start: Fühlt sich wie Belohnung für Erkundung an
- Balance: Nicht zu weit entfernt (unerreichbar), nicht zu nah (zu offensichtlich)

### Warum nur ein Kiesplatz?
- Einzigartigkeit: Macht das Feature besonders und einprägsam
- Narrative Bedeutung: Kann als besonderer Ort in der Spielwelt fungieren
- Performance: Begrenzt die Anzahl zusätzlicher Objekte in der Welt

## Konfiguration

Kiesplatz-Generierung anpassen durch Ändern der Konstanten:

- **Platzierungs-Radius**: `GRAVEL_AREA_PLACEMENT_RADIUS` ändern für größere/kleinere Suchbereich
- **Kiesplatz-Größe**: `GRAVEL_AREA_RADIUS` für größeren/kleineren Platz
- **Kiesel-Dichte**: `GRAVEL_PEBBLE_DENSITY` für mehr/weniger Kiesel
- **Tier-Anzahl**: `STONE_ANIMAL_COUNT_MIN/MAX` für mehr/weniger Tiere
- **Tier-Größen**: Konstanten in `procedural_models.gd` für Größe/Proportionen bearbeiten
- **Auswahl-Hash**: Modulo-Wert in `_place_gravel_area_with_stone_animals()` ändern

## Zukünftige Verbesserungen

Mögliche Erweiterungen:
- Weitere Steintier-Arten (Bär, Eichhörnchen, Eule, etc.)
- Komplexere Tier-Geometrie mit mehr Details
- Verschiedene Stein-Texturen oder -Farben
- Pfad der zum Kiesplatz führt (Quest-Integration)
- Interaktivität (Tiere untersuchen für Lore/Geschichte)
- Narrative Marker beim Kiesplatz
- Verschiedene Kiesplatz-Varianten (rund, oval, rechteckig)
- Zusätzliche Dekorationen (größere Steine, Pflanzen)

## Integration mit bestehenden Systemen

Das Kiesplatz-System integriert sich nahtlos mit:
- **Chunk-System**: Folgt gleicher Generierungspipeline wie andere einmalige Features
- **Terrain-System**: Nutzt Höhenabfragen für realistische Platzierung
- **Seed-System**: Vollständig deterministisch und reproduzierbar
- **See-System**: Vermeidet Seen (kein Kiesplatz in Seen)
- **Ozean-System**: Vermeidet Ozeanchunks
- **Gebirge-System**: Vermeidet einmaliges Gebirge (zu felsig)
- **Narrative Marker**: Könnte als Entdeckungspunkt oder Questziel dienen
- **Pfad-System**: Zukünftige Integration möglich (Pfad zum Kiesplatz)

## Dokumentation

Verwandte Dokumentation:
- [FISCHERBOOT_ZUSAMMENFASSUNG.md](FISCHERBOOT_ZUSAMMENFASSUNG.md) - Ähnliches einmaliges Feature-System
- [UNIQUE_MOUNTAIN_CHUNK_ZUSAMMENFASSUNG.md](UNIQUE_MOUNTAIN_CHUNK_ZUSAMMENFASSUNG.md) - Einmaliges Gebirge-System
- [FEATURES.md](FEATURES.md) - Feature-Übersicht
- [README.md](README.md) - Projekt-Übersicht

## Visuelle Beschreibung

Der Kiesplatz erscheint als:
- Kreisförmiger Bereich mit 8 Meter Radius
- Dicht bedeckt mit kleinen grauen Kieseln
- 4-8 abstrakte Steintiere verteilt im Bereich
- Verschiedene Tier-Silhouetten (Vogel, Hase, Reh, Fuchs)
- Natürlich in die Landschaft integriert
- Steintiere in grauem Stein, leicht unterschiedliche Grautöne für Kiesel

Die Steintiere sind bewusst abstrakt und geometrisch gehalten:
- Vogel: Klein, kompakt, mit Flügeln und Schnabel
- Hase: Niedrig, mit langen Ohren und rundlichem Körper
- Reh: Größer, elegant, mit Geweih und vier Beinen
- Fuchs: Mittelgroß, länglich, mit spitzem Kopf und buschigem Schwanz
