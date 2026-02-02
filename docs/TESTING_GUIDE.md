# Testing Guide - YouGame Godot 4 Project

## Überblick / Overview

Dieser Leitfaden erklärt wie man Tests schreibt, ausführt und wartet für das YouGame Projekt.

This guide explains how to write, run, and maintain tests for the YouGame project.

## Inhaltsverzeichnis / Table of Contents

1. [Running Tests](#running-tests)
2. [Writing New Tests](#writing-new-tests)
3. [Test Patterns](#test-patterns)
4. [CI/CD Integration](#cicd-integration)
5. [Best Practices](#best-practices)
6. [Troubleshooting](#troubleshooting)

---

## 1. Running Tests

### Lokal ausführen / Running Locally

```bash
# Alle Tests ausführen / Run all tests
./tests/run_tests.sh

# Einzelnen Test ausführen / Run a single test
godot --headless --path . res://tests/test_scene_chunk.tscn

# Mit Godot 4 headless
godot4 --headless --path . res://tests/test_scene_chunk.tscn
```

### Test-Ausgabe / Test Output

Tests geben strukturierte Ausgabe aus:
- ✓ PASS: Test name - Test erfolgreich
- ✗ FAIL: Test name - Test fehlgeschlagen
- ⏱️ TIMEOUT: Test name - Test Zeitüberschreitung

### Screenshots

Visual tests generieren Screenshots in `./test_screenshots/`:
- Automatisch in CI hochgeladen
- Hilfreich für visuelle Verifikation
- Können manuell überprüft werden

---

## 2. Writing New Tests

### Test-Struktur / Test Structure

Jeder Test benötigt zwei Dateien:

1. **Test Script** (`tests/test_<name>.gd`)
2. **Test Scene** (`tests/test_scene_<name>.tscn`)

### Minimal Test Template

```gdscript
extends Node
# Test script for <ComponentName>

const Component = preload("res://scripts/path/to/component.gd")

var test_count: int = 0
var passed_count: int = 0

func _ready() -> void:
    print("\n=== <COMPONENT NAME> TEST ===")
    
    # Run tests
    test_component_creation()
    test_component_behavior()
    
    # Print summary
    print("\n=== TEST SUMMARY ===")
    print("Tests run: ", test_count)
    print("Tests passed: ", passed_count)
    print("Tests failed: ", test_count - passed_count)
    
    if passed_count == test_count:
        print("✓ All tests passed!")
        get_tree().quit(0)
    else:
        print("✗ Some tests failed")
        get_tree().quit(1)

func test_component_creation() -> void:
    test_count += 1
    var test_name = "Component can be created"
    
    var component = Component.new()
    
    if component != null:
        pass_test(test_name)
    else:
        fail_test(test_name, "Component is null")
    
    component.free()

func test_component_behavior() -> void:
    test_count += 1
    var test_name = "Component behaves correctly"
    
    var component = Component.new()
    # Add behavior test logic here
    
    if true:  # Replace with actual condition
        pass_test(test_name)
    else:
        fail_test(test_name, "Behavior incorrect")
    
    component.free()

# Helper functions
func pass_test(test_name: String, message: String = "") -> void:
    passed_count += 1
    print("✓ PASS: ", test_name)
    if message != "":
        print("  ", message)

func fail_test(test_name: String, message: String) -> void:
    print("✗ FAIL: ", test_name)
    print("  ", message)
```

### Test Scene Template

```
[gd_scene load_steps=2 format=3 uid="uid://<unique_id>"]

[ext_resource type="Script" path="res://tests/test_<name>.gd" id="1_test"]

[node name="TestRunner" type="Node"]
script = ExtResource("1_test")
```

---

## 3. Test Patterns

### Unit Test Pattern

Tests für einzelne Komponenten isoliert:

```gdscript
func test_calculation() -> void:
    test_count += 1
    var test_name = "Math calculation is correct"
    
    var result = MyMath.add(2, 3)
    
    if result == 5:
        pass_test(test_name)
    else:
        fail_test(test_name, "Expected 5, got %d" % result)
```

### Async Test Pattern

Tests die auf Frames oder Timer warten:

```gdscript
func test_async_behavior() -> void:
    test_count += 1
    var test_name = "Async operation completes"
    
    var component = Component.new()
    add_child(component)
    
    # Wait for initialization
    await get_tree().process_frame
    
    # Wait for timer
    await get_tree().create_timer(0.5).timeout
    
    if component.is_ready:
        pass_test(test_name)
    else:
        fail_test(test_name, "Component not ready after wait")
    
    component.queue_free()
```

### Visual Test Pattern

Tests mit Screenshot-Capture:

```gdscript
const ScreenshotHelper = preload("res://tests/screenshot_helper.gd")

func test_visual_rendering() -> void:
    test_count += 1
    var test_name = "Visual element renders correctly"
    
    # Setup scene
    var visual_component = VisualComponent.new()
    add_child(visual_component)
    
    # Wait for rendering
    await ScreenshotHelper.wait_for_render(5)
    
    # Capture screenshot
    ScreenshotHelper.capture_screenshot("visual_test", "Testing visual rendering")
    
    pass_test(test_name, "Screenshot captured for manual verification")
    
    visual_component.queue_free()
```

### Integration Test Pattern

Tests für Interaktion mehrerer Komponenten:

```gdscript
func test_player_world_interaction() -> void:
    test_count += 1
    var test_name = "Player interacts with world correctly"
    
    # Create test scene
    var test_scene = Node3D.new()
    add_child(test_scene)
    
    # Add world manager
    var world = WorldManager.new()
    test_scene.add_child(world)
    
    # Add player
    var player = Player.new()
    test_scene.add_child(player)
    
    # Wait for initialization
    await get_tree().process_frame
    
    # Test interaction
    player.position = Vector3(10, 0, 10)
    await get_tree().create_timer(0.5).timeout
    
    var on_terrain = player.position.y > 0
    
    test_scene.queue_free()
    
    if on_terrain:
        pass_test(test_name)
    else:
        fail_test(test_name, "Player not properly positioned on terrain")
```

---

## 4. CI/CD Integration

### GitHub Actions Workflow

Tests laufen automatisch bei:
- Push zu `main` oder `develop` Branch
- Pull Requests zu `main`

### Pipeline Schritte / Pipeline Steps

1. **Script Validation** - Prüft auf Parse-Fehler
2. **Test Execution** - Führt alle Tests aus
3. **Screenshot Collection** - Sammelt Test-Screenshots
4. **Test Report** - Generiert Test-Bericht
5. **Artifact Upload** - Lädt Screenshots und Berichte hoch

### Test in neuen Branch hinzufügen

```bash
# 1. Test-Dateien erstellen
# tests/test_my_feature.gd
# tests/test_scene_my_feature.tscn

# 2. Test zum Runner hinzufügen
# Edit tests/run_tests.sh
tests=(
    ...
    "res://tests/test_scene_my_feature.tscn|My Feature Tests"
)

# 3. Lokal testen
./tests/run_tests.sh

# 4. Committen und pushen
git add tests/
git commit -m "Add tests for my feature"
git push
```

---

## 5. Best Practices

### DO ✅

- **Schreibe Tests zuerst** (TDD) wenn möglich
- **Isoliere Tests** - Jeder Test sollte unabhängig sein
- **Nutze aussagekräftige Namen** - `test_player_takes_fall_damage` statt `test1`
- **Teste Edge Cases** - Null-Werte, Grenzwerte, ungültige Inputs
- **Cleanup nach Tests** - Benutze `.free()` oder `.queue_free()`
- **Benutze Konstanten** - Seeds für deterministisches Verhalten
- **Dokumentiere Tests** - Kommentare für komplexe Logik
- **Halte Tests schnell** - Unter 1 Minute pro Test

### DON'T ❌

- **Keine Dependencies zwischen Tests** - Tests sollten in beliebiger Reihenfolge laufen
- **Keine externen Ressourcen** - Tests sollten offline funktionieren
- **Keine zufälligen Failures** - Tests müssen deterministisch sein
- **Keine hardcodierten Pfade** - Benutze relative `res://` Pfade
- **Keine Tests überspringen** - Repariere oder entferne sie
- **Keine zu langen Tests** - Splitte in mehrere Testfunktionen
- **Keine Produktionsdaten ändern** - Nur Test-Daten verwenden

### Test Kategorien

Organisiere Tests in Kategorien:

- **Unit Tests** - Einzelne Komponenten (`test_chunk.gd`)
- **Integration Tests** - Mehrere Komponenten (`test_save_load.gd`)
- **Visual Tests** - UI und Rendering (`test_path_visual.gd`)
- **System Tests** - Komplette Features (`test_jetpack_*.gd`)

---

## 6. Troubleshooting

### Test läuft nicht

**Problem:** Test wird nicht ausgeführt

**Lösung:**
1. Prüfe dass Test in `tests/run_tests.sh` eingetragen ist
2. Prüfe Dateinamen: `test_<name>.gd` und `test_scene_<name>.tscn`
3. Prüfe dass Scene-Datei korrekten Script-Pfad hat
4. Teste manuell: `godot --headless --path . res://tests/test_scene_<name>.tscn`

### Test-Timeout

**Problem:** Test überschreitet Zeitlimit (60 Sekunden)

**Lösung:**
1. Reduziere Wait-Zeiten in Test
2. Entferne unnötige `await` Calls
3. Splitte Test in kleinere Tests
4. Prüfe auf Endlosschleifen

### Headless Rendering Errors

**Problem:** Warnungen über fehlende Meshes im Headless Mode

**Lösung:**
- Ignoriere `mesh_get_surface_count` Fehler
- Diese sind normal im Headless Mode
- Werden automatisch gefiltert in `run_tests.sh`

### Screenshots nicht generiert

**Problem:** Screenshots fehlen in Artifacts

**Lösung:**
1. Prüfe dass `ScreenshotHelper` korrekt benutzt wird
2. Prüfe Godot User Directory Pfad
3. Teste lokal in `./test_screenshots/`

### Tests lokal erfolgreich, CI fehlschlägt

**Problem:** Tests passen lokal aber nicht in CI

**Lösung:**
1. Prüfe Godot Version (CI benutzt 4.3.0)
2. Prüfe OS-spezifisches Verhalten
3. Prüfe Zeitabhängigkeiten (CI kann langsamer sein)
4. Erhöhe Timeouts wenn nötig

---

## Anhang / Appendix

### Nützliche Befehle / Useful Commands

```bash
# Nur bestimmte Tests ausführen
godot --headless --path . res://tests/test_scene_chunk.tscn

# Test mit mehr Output
godot --headless --path . --verbose res://tests/test_scene_chunk.tscn

# Alle GDScript Dateien validieren
godot --headless --path . --check-only --quit

# Test-Coverage Check (manuell)
find tests/ -name "test_*.gd" | wc -l
find scripts/ -name "*.gd" | wc -l
```

### Ressourcen / Resources

- [Godot Testing Documentation](https://docs.godotengine.org/en/stable/)
- [GDScript Best Practices](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- [GitHub Actions Godot](https://github.com/chickensoft-games/setup-godot)
- [TEST_STRATEGY.md](./TEST_STRATEGY.md) - Detaillierte Teststrategie

---

**Version:** 1.0  
**Letztes Update:** 2026-02-02  
**Maintainer:** Development Team
