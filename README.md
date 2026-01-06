Erstelle ein Godot 4 Projekt mit 3D-Template und Android-Export aktiviert.
Konfiguriere Android SDK, JDK und Export-Presets, sodass ein APK-Build möglich ist.
Lege eine klare Projektstruktur an (scenes, scripts, assets, tests).
Implementiere einen WorldManager, der Chunks rund um den Spieler lädt und entfernt.
Teile die Welt in quadratische Terrain-Chunks mit fester Größe.
Nutze eine seed-basierte Heightmap (Noise) zur Terrain-Generierung.
Übernimm Randhöhen benachbarter Chunks, um sichtbare Brüche zu vermeiden.
Berechne pro Zelle die Steigung des Terrains.
Markiere Flächen mit Steigung ≤ 30° als begehbar.
Stelle sicher, dass mindestens 80 % der Chunk-Fläche begehbar sind.
Verwende Flood-Fill, um eine begehbare Verbindung zu angrenzenden Chunks zu prüfen.
Glätte Terrain lokal, wenn keine erreichbare Verbindung existiert.
Platziere Low-Poly-Assets nur auf geeigneten Flächen.
Implementiere einfache NPC-Zustandsmaschinen (Idle, Walk).
Lege pro Chunk Meta-Daten wie Biome, Offenheit und Landmark-Typen ab.
Erzeuge Narrative Marker ohne festen Story-Text.
Implementiere ein Quest-Hook-System, das Marker für Aufgaben auswählt.
Füge Debug-Visualisierungen für Chunk-Grenzen und Begehbarkeit hinzu.
Optimiere strikt für Android-Performance (LOD, Instancing, kein teurer Code pro Frame).
Automatisiere den APK-Build per CLI und füge Tests für Seed-Reproduzierbarkeit und Begehbarkeit hinzu.# YouGame_godot4
