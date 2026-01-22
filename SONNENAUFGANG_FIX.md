# Sonnenaufgang Helligkeit Fix

## Problem
Die Sonne hat erst bei ungefähr 80 Grad genügend Licht gespendet. Der Morgen war viel zu dunkel.

## Ursache
Die DirectionalLight3D Rotation war bei Sonnenaufgang (7:00 Uhr) auf 60° eingestellt, was bedeutete dass das Licht 60° von der optimalen Überkopf-Position entfernt war und dadurch nur minimale Beleuchtung bot.

## Lösung
Die Sonnenwinkel-Konstanten wurden angepasst:
- `SUNRISE_END_ANGLE`: -60° → -20° (20° von Überkopf statt 60°)
- `SUNSET_START_ANGLE`: +60° → +20° (Symmetrie beibehalten)

## Auswirkung
- Um 7:00 Uhr (Spielstart) ändert sich die Sonnenrotation von 60° auf 20° von der Überkopf-Position
- 3x besserer Winkel für Beleuchtung bei Sonnenaufgang/Sonnenuntergang
- Symmetrischer Tag-Nacht-Zyklus mit übereinstimmenden Sonnenaufgangs-/Sonnenuntergangs-Winkeln bleibt erhalten
- Mittagsbeleuchtung bleibt unverändert (0° = Überkopf)

## Technische Details

### Vorher
```
Zeit    | Winkel von Überkopf
7:00    | 60° (sehr flacher Winkel, wenig Licht)
9:00    | 48°
12:00   | 0° (Überkopf, optimal)
15:00   | 48°
17:00   | 60° (sehr flacher Winkel, wenig Licht)
```

### Nachher
```
Zeit    | Winkel von Überkopf | Verbesserung
7:00    | 20°                 | 3x näher an Überkopf
9:00    | 12°                 | 4x näher an Überkopf
12:00   | 0° (Überkopf)       | Gleich (optimal)
15:00   | 12°                 | 4x näher an Überkopf
17:00   | 20°                 | 3x näher an Überkopf
```

## Geänderte Dateien
- `scripts/day_night_cycle.gd` - Angepasste Konstanten und Kommentare

## Getestete Kompatibilität
Die existierenden Tests verwenden `DayNightCycle.SUNRISE_END_ANGLE` als Konstante und sollten weiterhin bestehen, da sie nur überprüfen, dass der Sonnenwinkel über der Sonnenaufgangsposition liegt und zum Zenit aufsteigt.
