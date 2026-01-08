# Asset Import Guide für YouGame (Godot 4)

Dieses HowTo erklärt Schritt für Schritt, wie kostenlose 3D-Modelle (Tiere, Pflanzen, Charaktere) heruntergeladen, aufbereitet und in Godot 4 importiert werden – mit Fokus auf mobile Performance und Best Practices.

## Inhaltsverzeichnis

1. [Empfohlene Ordnerstruktur](#empfohlene-ordnerstruktur)
2. [Bevorzugte Dateiformate](#bevorzugte-dateiformate)
3. [Minimaler Workflow](#minimaler-workflow)
4. [Godot 4 Import-Einstellungen](#godot-4-import-einstellungen)
5. [Animationen & Retargeting](#animationen--retargeting)
6. [Pflanzen-Rendering-Tipps](#pflanzen-rendering-tipps)
7. [Wind-Shader für Vegetation](#wind-shader-für-vegetation)
8. [Performance-Tipps für Mobile](#performance-tipps-für-mobile)
9. [Lizenz & Attribution](#lizenz--attribution)
10. [Empfohlene Asset-Quellen](#empfohlene-asset-quellen)
11. [Schritt-für-Schritt Checkliste](#schritt-für-schritt-checkliste)

---

## Empfohlene Ordnerstruktur

Organisiere dein Projekt wie folgt, um Assets sauber zu trennen und wiederzufinden:

```
YouGame_godot4/
├── assets/
│   ├── models/
│   │   ├── creatures/      # Tiere, NPCs, Charaktere
│   │   └── plants/         # Bäume, Gras, Vegetation
│   ├── textures/           # Separate Texturen (falls nicht im .glb enthalten)
│   └── animations/         # Standalone-Animationen (.res, .anim)
├── scenes/
│   ├── characters/         # Fertige Character-Prefabs (.tscn)
│   └── vegetation/         # Fertige Pflanzen-Prefabs (.tscn)
└── docs/
    └── ASSET_CREDITS.md    # Dokumentation aller verwendeten Assets
```

**Wichtig:** Nutze die `.gitkeep` Dateien in leeren Ordnern, damit Git die Struktur beibehält.

---

## Bevorzugte Dateiformate

### 3D-Modelle

**Primärformat: glTF 2.0 (.glb oder .gltf)**
- Standardformat für moderne 3D-Assets
- Wird von Godot 4 nativ gut unterstützt
- Enthält Meshes, Texturen, Animationen und Materialien in einer Datei
- Binär (.glb) ist kompakter als Text (.gltf + separate Dateien)

**Alternative Formate:**
- `.fbx` (funktioniert, aber glTF ist besser unterstützt)
- `.obj` (nur Geometrie, keine Animationen/Materialien)

### Texturen

**PNG** (verlustfrei, mit Alpha-Kanal)
- Für Albedo/Diffuse mit Transparenz
- Ideal für UI-Texturen

**JPEG** (verlustbehaftet, kleiner)
- Für Texturen ohne Alpha-Kanal
- Gute Kompression für Mobile

**KTX2 / Basis Universal** (optional, empfohlen für Mobile)
- GPU-komprimierte Texturen
- Deutlich weniger VRAM-Verbrauch
- Godot 4 unterstützt automatisches Konvertieren zu KTX2

**Empfehlung:** Beginne mit PNG/JPEG, nutze KTX2 später für Performance-Optimierung.

---

## Minimaler Workflow

### 1. Download

Lade ein kostenloses 3D-Modell von einer vertrauenswürdigen Quelle herunter (siehe [Empfohlene Quellen](#empfohlene-asset-quellen)).

### 2. Optionale Bearbeitung in Blender

Falls das Modell nicht im `.glb` Format vorliegt oder angepasst werden muss:

1. **Blender öffnen** (kostenlos: https://www.blender.org)
2. **Import:** `File > Import` → wähle das Format (FBX, OBJ, etc.)
3. **Optionale Anpassungen:**
   - Rotation/Skalierung korrigieren
   - UV-Maps prüfen
   - Texturen zuweisen
   - Animationen säubern
4. **Export als glTF 2.0:**
   - `File > Export > glTF 2.0 (.glb/.gltf)`
   - Format: `glTF Binary (.glb)` wählen
   - Export-Optionen:
     - ✅ Include: Selected Objects (falls nur bestimmte Objekte)
     - ✅ Include: Animations (falls vorhanden)
     - ✅ Compression: Aktiviert für kleinere Dateien
   - Export nach `assets/models/creatures/` oder `assets/models/plants/`

### 3. Ablage ins Projekt

Kopiere die `.glb` Datei in den entsprechenden Ordner:

```bash
# Beispiel: Ein Fuchs-Modell
assets/models/creatures/fox.glb
```

### 4. Godot Import

Godot erkennt `.glb` Dateien automatisch:

1. **FileSystem** in Godot öffnen
2. Navigiere zu `assets/models/creatures/fox.glb`
3. Doppelklick → Import-Dialog öffnet sich
4. Import-Einstellungen anpassen (siehe nächster Abschnitt)
5. **Reimport** klicken

### 5. Erstellen einer Godot-Prefab (.tscn)

Erstelle eine wiederverwendbare Szene:

1. **Neue Szene erstellen:** Scene > New Scene
2. **Wurzelknoten:** `CharacterBody3D` (für Charaktere) oder `Node3D` (für statische Objekte)
3. **glTF-Szene instanziieren:**
   - Rechtsklick auf Wurzel > Add Child Node > suche nach deinem importierten Modell
   - Oder: Drag & Drop der `.glb` Datei in die Szene
4. **Skripte hinzufügen:** Falls Logik benötigt wird (z.B. `player.gd`)
5. **Speichern:** `scenes/characters/fox.tscn`

---

## Godot 4 Import-Einstellungen

Beim Import von `.glb` Dateien gibt es wichtige Einstellungen:

### Import-Optionen (Rechtsklick auf .glb > Reimport)

**Nodes:**
- **Root Type:** Lasse auf "Node3D" oder wähle "CharacterBody3D" für bewegliche Charaktere
- **Root Name:** Optional umbenennen

**Meshes:**
- **Ensure Tangents:** ✅ Aktivieren (für Normal-Maps)
- **Generate LODs:** ✅ Aktivieren (automatische Level-of-Detail für Performance)
- **Create Shadow Meshes:** ✅ Aktivieren (für bessere Schatten-Performance)
- **Light Baking:** Optional (falls statische Beleuchtung verwendet wird)

**Skins:**
- **Create Skeleton:** ✅ Aktivieren (falls Skelett vorhanden)

**Animations:**
- **Import:** ✅ Aktivieren
- **FPS:** 30 oder 60 (abhängig von Quelle)
- **Trimming:** Optional, um leere Frames zu entfernen
- **Optimizer:** ✅ Aktivieren (reduziert Keyframes)

**Materials:**
- **Import Materials:** ✅ Aktivieren
- **Material Caching:** ✅ Aktivieren (wiederverwendbare Materialien)

### Mobile UI Hinweise

**Anchors & Viewport für mobile UI:**

Falls du UI-Elemente für mobile Geräte erstellst (unabhängig von 3D-Assets):

```gdscript
# Beispiel: UI-Button im mobile_controls.gd anpassen
extends Control

func _ready():
    # Anchor auf Bottom-Right setzen
    anchor_left = 1.0
    anchor_top = 1.0
    anchor_right = 1.0
    anchor_bottom = 1.0
    
    # Offset für Abstand vom Rand
    offset_left = -100
    offset_top = -100
```

---

## Animationen & Retargeting

### Workflow: Mixamo → Blender → Godot

**Mixamo** (https://www.mixamo.com) bietet kostenlose Charakter-Animationen.

#### 1. Mixamo Download

1. Gehe zu Mixamo und wähle eine Animation (z.B. "Walking")
2. Download-Einstellungen:
   - **Format:** FBX for Unity (funktioniert auch für Godot)
   - **Skin:** With Skin (falls das Modell von Mixamo stammt)
   - **Frames per second:** 30

#### 2. Blender Import & Retargeting

Falls du ein eigenes Modell hast und nur die Animation von Mixamo nutzen willst:

1. **Import Mixamo FBX:** `File > Import > FBX`
2. **Import eigenes Modell** (falls separat)
3. **Retargeting:**
   - Nutze Blenders Addon "Rigify" oder "Auto-Rig Pro" (kostenpflichtig)
   - Oder manuell: Knochen Namen angleichen und Constraints setzen
   - Einfacher: Nutze das Mixamo-Skelett direkt

4. **Export als glTF 2.0:**
   - Wähle Armature + Mesh + Animation
   - Export nach `assets/animations/walk.glb` oder direkt in `assets/models/creatures/`

#### 3. Godot AnimationPlayer & AnimationTree

Nach dem Import:

1. **AnimationPlayer** nutzen für einfache Animationen:

```gdscript
# Beispiel: Animation abspielen
$AnimationPlayer.play("walk")
```

2. **AnimationTree** für komplexe Übergänge:

```gdscript
# Erstelle einen AnimationTree-Knoten in der Szene
# Setze AnimationPlayer als Source
# Erstelle eine State Machine oder Blend Tree

# Im Skript:
$AnimationTree.active = true
$AnimationTree.set("parameters/walk_speed/scale", 1.5)
```

**Blend-Beispiel (Idle → Walk):**

1. Erstelle AnimationTree mit BlendSpace1D
2. Füge "idle" und "walk" Animationen hinzu
3. Steuere per Parameter:

```gdscript
var velocity = Vector3.ZERO
var blend_position = velocity.length() / max_speed
$AnimationTree.set("parameters/movement/blend_position", blend_position)
```

---

## Pflanzen-Rendering-Tipps

Vegetation kann Performance-intensiv sein. Hier sind bewährte Techniken:

### 1. Billboards für ferne Vegetation

Für Gras und kleine Pflanzen in der Ferne:

```gdscript
# Erstelle ein Billboard Sprite3D
extends Sprite3D

func _ready():
    billboard = BaseMaterial3D.BILLBOARD_ENABLED
    texture = preload("res://assets/textures/grass_billboard.png")
    alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
```

### 2. MultiMeshInstance3D für viele Instanzen

Für wiederholte Objekte (Bäume, Steine):

```gdscript
extends MultiMeshInstance3D

func _ready():
    # Erstelle MultiMesh
    multimesh = MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.instance_count = 1000
    
    # Setze Mesh (z.B. ein Baum)
    var tree_mesh = preload("res://assets/models/plants/tree.glb").instantiate()
    multimesh.mesh = tree_mesh.get_child(0).mesh
    
    # Verteile Instanzen zufällig
    for i in range(multimesh.instance_count):
        var transform = Transform3D()
        transform.origin = Vector3(
            randf_range(-100, 100),
            0,
            randf_range(-100, 100)
        )
        transform = transform.rotated(Vector3.UP, randf_range(0, TAU))
        multimesh.set_instance_transform(i, transform)
```

**Performance-Gewinn:** Statt 1000 einzelnen Nodes nur 1 MultiMeshInstance3D!

### 3. LOD (Level of Detail)

Nutze mehrere Modell-Varianten:

```gdscript
extends Node3D

@export var lod_distances = [10.0, 30.0, 60.0]
@export var lod_meshes: Array[Mesh]

func _process(_delta):
    var camera = get_viewport().get_camera_3d()
    var distance = global_position.distance_to(camera.global_position)
    
    for i in range(lod_distances.size()):
        if distance < lod_distances[i]:
            $MeshInstance3D.mesh = lod_meshes[i]
            break
```

---

## Wind-Shader für Vegetation

Ein einfacher Vertex-Shader für wiegenden Wind:

### Shader-Code (wind_vegetation.gdshader)

```glsl
shader_type spatial;

uniform float wind_strength : hint_range(0.0, 2.0) = 0.5;
uniform float wind_speed : hint_range(0.0, 5.0) = 1.0;
uniform vec2 wind_direction = vec2(1.0, 0.5);

void vertex() {
    // Nur obere Vertices bewegen (basierend auf Y-Position)
    float vertex_height = VERTEX.y;
    float height_factor = clamp(vertex_height / 2.0, 0.0, 1.0);
    
    // Wind-Offset berechnen
    float wind_wave = sin(TIME * wind_speed + VERTEX.x * 0.5 + VERTEX.z * 0.5);
    vec3 wind_offset = vec3(
        wind_direction.x * wind_wave * wind_strength * height_factor,
        0.0,
        wind_direction.y * wind_wave * wind_strength * height_factor
    );
    
    VERTEX += wind_offset;
}

void fragment() {
    // Standard-Material (kann erweitert werden)
    ALBEDO = vec3(0.3, 0.6, 0.2); // Grün für Pflanzen
}
```

### Verwendung im Material

1. **Neues ShaderMaterial erstellen:**
   - Rechtsklick im FileSystem > New Resource > ShaderMaterial
   - Shader zuweisen: Lade `wind_vegetation.gdshader`

2. **Material dem Modell zuweisen:**
   - Wähle dein Pflanzen-Mesh (z.B. Baum)
   - Im Inspector: Material Override → Dein ShaderMaterial

3. **Parameter anpassen:**
   - `wind_strength`: 0.5 für sanften Wind, 2.0 für Sturm
   - `wind_speed`: 1.0 normal, 3.0 schneller
   - `wind_direction`: (1.0, 0.0) für Wind von links

### Verbessertes Wind-Beispiel (mit Noise)

Für realistischeren Wind mit Perlin Noise:

```glsl
shader_type spatial;

uniform float wind_strength = 0.5;
uniform float wind_speed = 1.0;
uniform sampler2D noise_texture; // Verwende ein Noise-Texture

void vertex() {
    vec2 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
    
    // Sample Noise für variablen Wind
    vec2 noise_uv = world_pos * 0.01 + TIME * wind_speed * 0.1;
    float noise = texture(noise_texture, noise_uv).r;
    
    float height_factor = clamp(VERTEX.y / 2.0, 0.0, 1.0);
    vec3 wind_offset = vec3(
        noise * wind_strength * height_factor,
        0.0,
        noise * wind_strength * height_factor * 0.5
    );
    
    VERTEX += wind_offset;
}
```

---

## Performance-Tipps für Mobile

Mobile Geräte haben limitierte GPU/CPU-Leistung. Beachte folgendes:

### 1. Texturgrößen reduzieren

**Empfohlene Auflösungen:**
- Charaktere (nah): 1024x1024 oder 2048x2048
- Umgebungsobjekte: 512x512 oder 1024x1024
- Vegetation (fern): 256x256 oder 512x512
- UI-Elemente: 512x512 maximal

**Tool-Tipp:** Nutze Godot's Import-Option "Compress > VRAM Compressed" oder KTX2.

### 2. Polygon-Budget

**Richtwerte pro Objekt:**
- Hauptcharakter: 5.000 - 15.000 Triangles
- NPCs/Tiere: 2.000 - 8.000 Triangles
- Vegetation: 500 - 2.000 Triangles (mit LOD weniger)
- Umgebung (Steine, Props): 200 - 1.000 Triangles

**Gesamtbudget pro Frame:** Max. 100.000 - 300.000 Triangles (abhängig vom Gerät)

### 3. MultiMesh statt einzelner Nodes

Nutze `MultiMeshInstance3D` für wiederholte Objekte (siehe oben).

**Beispiel:**
- ❌ 500 einzelne Gras-Node3D → 500 Draw Calls
- ✅ 1 MultiMeshInstance3D mit 500 Instanzen → 1 Draw Call

### 4. KTX2 / Basis Universal Texturen

Godot 4 kann PNGs automatisch zu KTX2 konvertieren:

1. **Projekt-Einstellungen:**
   - Project > Project Settings > Rendering > Textures
   - **VRAM Compression:** Aktiviere "Import ETC2 ASTC" (für Mobile)

2. **Pro Textur:**
   - Wähle Textur im FileSystem
   - Import-Tab: Compress > VRAM Compressed
   - Reimport

**Vorteil:** 4-8x weniger VRAM-Verbrauch!

### 5. Frustum Culling & Occlusion Culling

Godot macht Frustum Culling automatisch. Für Occlusion Culling:

- Nutze `VisibleOnScreenNotifier3D` für große Objekte
- Occlusion Culling ist in Godot 4 noch experimentell

### 6. Shadow Maps limitieren

Für mobile:
- **Directional Light:** Max. 2048x2048 Shadow Map
- **Omni/Spot Lights:** Max. 512x512 oder weniger
- Deaktiviere Schatten für kleine/ferne Objekte

```gdscript
# Schatten für entfernte Objekte deaktivieren
$MeshInstance3D.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
```

### 7. Draw Calls minimieren

- **Batching:** Nutze MultiMesh
- **Atlas Textures:** Kombiniere mehrere Texturen in einem Atlas
- **Material Sharing:** Wiederverwendung gleicher Materialien

**Ziel:** < 100 Draw Calls für Mobile

---

## Lizenz & Attribution

### Lizenzen verstehen

**CC0 (Public Domain):**
- ✅ Kostenlos, kommerziell nutzbar
- ✅ Keine Attribution erforderlich (aber höflich)
- ✅ Änderungen erlaubt

**CC-BY 4.0:**
- ✅ Kostenlos, kommerziell nutzbar
- ⚠️ **Attribution Pflicht!** Ersteller nennen
- ✅ Änderungen erlaubt

**MIT / Apache:**
- ✅ Für Software/Code üblich
- ✅ Kommerziell nutzbar
- ⚠️ Lizenztext beilegen

**Proprietär / Custom:**
- ⚠️ Immer Bedingungen prüfen!
- Oft: Nur für non-commercial oder mit Einschränkungen

### Pflege von docs/ASSET_CREDITS.md

Für jedes neue Asset:

1. **Kopiere Template** aus `docs/ASSET_CREDITS_TEMPLATE.md`
2. **Fülle Felder aus:**
   - Asset-Name
   - Pfad im Repo
   - Quelle/URL
   - Autor
   - Lizenz
   - Verwendung
3. **Commit:** `git add docs/ASSET_CREDITS.md && git commit -m "docs: add credits for fox model"`

**Beispiel-Eintrag:**

```markdown
### Low-Poly Fox

**Pfad:** `assets/models/creatures/fox.glb`  
**Quelle:** https://quaternius.com/packs/ultimateanimals.html  
**Autor:** Quaternius  
**Lizenz:** CC0  
**Verwendung:** scenes/characters/fox.tscn  
**Hinweise:** Keine Änderungen
```

---

## Empfohlene Asset-Quellen

Hier sind vertrauenswürdige Quellen für kostenlose 3D-Assets:

### 1. Quaternius
- **URL:** https://quaternius.com
- **Inhalte:** Low-Poly Tiere, Charaktere, Vegetation, Props
- **Lizenz:** CC0 (Public Domain)
- **Format:** glTF (.glb), FBX
- **Tipp:** Ultimate Animals Pack, Nature Pack

### 2. Kenney
- **URL:** https://kenney.nl/assets
- **Inhalte:** Game Assets (3D, 2D, UI, Audio)
- **Lizenz:** CC0
- **Format:** OBJ, FBX, PNG
- **Tipp:** Sehr konsistenter Low-Poly Stil

### 3. Poly Haven (ehemals Poly Pizza)
- **URL:** https://polyhaven.com
- **Inhalte:** High-Quality 3D-Modelle, HDRIs, Texturen
- **Lizenz:** CC0
- **Format:** glTF, FBX, Blend
- **Tipp:** Realistische Modelle, aber höherer Poly-Count (ggf. in Blender reduzieren)

### 4. Mixamo
- **URL:** https://www.mixamo.com
- **Inhalte:** Charaktere + Animationen
- **Lizenz:** Kostenlos für Spiele (kein Weiterverkauf der Rohdaten)
- **Format:** FBX
- **Tipp:** Auto-Rigging und große Animations-Bibliothek

### 5. OpenGameArt
- **URL:** https://opengameart.org
- **Inhalte:** Community-getrieben, 2D + 3D
- **Lizenz:** Variiert! **Immer prüfen!**
- **Format:** Variiert
- **Tipp:** Gute Vielfalt, aber Qualität schwankt

### ⚠️ Wichtig: Lizenz immer prüfen!

Auch bei "kostenlosen" Assets:
- Lese die Lizenzbedingungen **vor** der Nutzung
- Achte auf Einschränkungen (kommerziell, Attribution, etc.)
- Dokumentiere in `docs/ASSET_CREDITS.md`

---

## Schritt-für-Schritt Checkliste

Nutze diese Checkliste beim Hinzufügen eines neuen Assets:

### ✅ Download & Vorbereitung

- [ ] Asset von vertrauenswürdiger Quelle herunterladen
- [ ] Lizenz überprüfen und dokumentieren
- [ ] Falls nötig: In Blender öffnen und zu `.glb` exportieren

### ✅ Import in Godot

- [ ] `.glb` Datei in `assets/models/creatures/` oder `assets/models/plants/` kopieren
- [ ] Godot FileSystem aktualisieren (F5 oder Reload)
- [ ] Doppelklick auf `.glb` → Import-Einstellungen anpassen:
  - [ ] Ensure Tangents: ✅
  - [ ] Generate LODs: ✅
  - [ ] Create Shadow Meshes: ✅
  - [ ] Animations importieren: ✅ (falls vorhanden)
- [ ] **Reimport** klicken

### ✅ Prefab erstellen

- [ ] Neue Szene erstellen (`Scene > New Scene`)
- [ ] Wurzelknoten wählen: `CharacterBody3D`, `StaticBody3D` oder `Node3D`
- [ ] Importiertes Modell als Child hinzufügen (Drag & Drop)
- [ ] Optional: Kollisionsformen (`CollisionShape3D`) hinzufügen
- [ ] Optional: Skript anhängen (z.B. `player.gd`)
- [ ] Szene speichern: `scenes/characters/[name].tscn` oder `scenes/vegetation/[name].tscn`

### ✅ Performance-Check

- [ ] Polygon-Count prüfen (sollte < 15.000 für Charaktere sein)
- [ ] Texturgrößen überprüfen (max. 2048x2048 für Mobile)
- [ ] Falls viele Instanzen: `MultiMeshInstance3D` nutzen
- [ ] LOD-Meshes erstellen (optional)
- [ ] Shadow Casting deaktivieren für kleine/ferne Objekte

### ✅ Dokumentation

- [ ] Eintrag in `docs/ASSET_CREDITS.md` erstellen (nutze Template)
- [ ] Felder ausfüllen:
  - [ ] Asset-Name
  - [ ] Pfad im Repo
  - [ ] Quelle/URL
  - [ ] Autor
  - [ ] Lizenz
  - [ ] Verwendung
  - [ ] Hinweise (optional)
- [ ] Git Commit: `git add . && git commit -m "feat: add [asset name] model"`

### ✅ Testing

- [ ] Asset in Testszene platzieren
- [ ] Im Editor testen (Play-Button)
- [ ] Auf Mobile exportieren und testen (falls möglich)
- [ ] Animationen abspielen (falls vorhanden)
- [ ] Shader/Materialien prüfen

---

## Weiterführende Ressourcen

- **Godot Dokumentation:** https://docs.godotengine.org/en/stable/
- **Blender Tutorials:** https://www.blender.org/support/tutorials/
- **glTF Best Practices:** https://www.khronos.org/gltf/
- **Mobile Optimization:** https://docs.godotengine.org/en/stable/tutorials/performance/

---

## Fragen oder Probleme?

Falls du Fragen hast oder auf Probleme stößt:
1. Prüfe die [Godot Dokumentation](https://docs.godotengine.org)
2. Durchsuche [Godot Community Forums](https://forum.godotengine.org)
3. Erstelle ein Issue im Repository

Viel Erfolg beim Hinzufügen deiner Assets! 🎮🌲🦊
