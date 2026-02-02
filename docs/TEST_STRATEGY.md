# Test Strategy - YouGame Godot 4 Project

## Übersicht / Overview

Dieses Dokument definiert die Teststrategie für das YouGame Projekt, um eine vollständige kritische Testabdeckung zu erreichen.

This document defines the testing strategy for the YouGame project to achieve complete critical test coverage.

## 1. Testebenen / Test Levels

### 1.1 Unit Tests
**Ziel:** Einzelne Komponenten und Funktionen isoliert testen  
**Goal:** Test individual components and functions in isolation

**Kritische Komponenten mit Unit Tests:**
- ✅ Chunk Generation (test_chunk.gd)
- ✅ Day/Night Cycle (test_day_night_cycle.gd)
- ✅ Campfire System (test_campfire_system.gd)
- ✅ Crystal System (test_crystal_system.gd)
- ✅ Flashlight System (test_flashlight_system.gd)
- ✅ Torch System (test_torch_system.gd)
- ⚠️  Player System (existiert, braucht Erweiterung / exists, needs expansion)
- ⚠️  NPC System (fehlt / missing)
- ⚠️  World Manager (fehlt / missing)
- ⚠️  Quest Hook System (fehlt / missing)
- ⚠️  Weather System (teilweise / partial - test_sky_weather.gd, test_wind_snow.gd)
- ⚠️  Herb System (fehlt / missing)
- ⚠️  Cluster System (existiert / exists - test_clusters.gd)

### 1.2 Integration Tests
**Ziel:** Zusammenspiel mehrerer Komponenten testen  
**Goal:** Test interaction between multiple components

**Kritische Integrationen:**
- ✅ Save/Load System (test_save_load.gd, test_quick_save_integration.gd)
- ✅ Mobile Controls Integration (test_mobile_controls.gd)
- ✅ Widget Integration (test_widget_integration.gd)
- ✅ Path System Integration (test_path_system.gd, test_path_continuity.gd)
- ⚠️  Player-World Interaction (teilweise durch Fall Damage Tests)
- ⚠️  UI-Game State Synchronization (teilweise / partial)
- ⚠️  Quest System Integration (fehlt / missing)

### 1.3 Visual/UI Tests
**Ziel:** Visuelle Korrektheit und UI-Verhalten testen  
**Goal:** Test visual correctness and UI behavior

**Kritische visuelle Tests:**
- ✅ Path Rendering (test_path_visual.gd)
- ✅ Ocean Visual (test_ocean_visual.gd)
- ✅ Fishing Boat Visual (test_fishing_boat_visual.gd)
- ✅ Mobile Controls Visibility (test_mobile_controls.gd)
- ✅ Pause Menu (test_pause_menu.gd)
- ✅ Ruler Overlay (test_ruler_overlay.gd)
- ✅ Minimap Reveal (test_minimap_reveal_radius.gd)
- ✅ Direction Arrows (through screenshot tests)

### 1.4 System/E2E Tests
**Ziel:** Komplette Spielszenarien testen  
**Goal:** Test complete game scenarios

**Kritische Szenarien:**
- ✅ Fall Damage & Ocean Cliffs (test_fall_damage.gd, test_ocean_cliffs.gd)
- ✅ Jetpack Features (multiple test files)
- ✅ Player Lockout on Load (test_player_lockout_load.gd)
- ⚠️  Complete Game Loop (fehlt / missing)
- ⚠️  Resource Collection Flow (teilweise / partial)

## 2. Test-Pyramide / Test Pyramid

```
        /\
       /E2E\       <- Wenige, aber kritische (Few but critical)
      /------\
     /Integr.\    <- Mittlere Anzahl (Medium number)
    /----------\
   / UI/Visual \  <- Wichtig für Android (Important for Android)
  /--------------\
 /   Unit Tests  \ <- Viele, schnelle Tests (Many fast tests)
/------------------\
```

## 3. Kritische Systeme die getestet werden müssen

### Höchste Priorität (Must Have)
1. **World Generation System**
   - ✅ Chunk generation and reproducibility
   - ⚠️  World manager chunk loading/unloading (needs test)
   - ⚠️  Cluster system (has test but needs verification)
   - ✅ Path generation and continuity

2. **Player Systems**
   - ⚠️  Movement and physics (needs comprehensive test)
   - ✅ Fall damage
   - ✅ Jetpack mechanics (comprehensive)
   - ⚠️  Health system (needs test)

3. **Save/Load System**
   - ✅ Save game manager
   - ✅ Quick save integration
   - ✅ Widget data export
   - ⚠️  Corruption handling (needs test)

4. **Core Game Mechanics**
   - ✅ Day/Night cycle
   - ✅ Collection systems (campfire, crystal, torch, flashlight)
   - ⚠️  Quest system (needs test)
   - ⚠️  NPC system (needs test)

### Hohe Priorität (Should Have)
5. **UI Systems**
   - ✅ Mobile controls
   - ✅ Pause menu
   - ✅ Minimap
   - ✅ Ruler overlay
   - ⚠️  UI Manager (needs comprehensive test)

6. **Environmental Systems**
   - ✅ Weather (partial coverage)
   - ⚠️  Ocean and lighthouse (visual tests exist)
   - ⚠️  Terrain features (mountains, forests, etc.)

### Mittlere Priorität (Nice to Have)
7. **Visual & Polish**
   - ✅ Path rendering
   - ✅ Ocean visuals
   - ✅ Animated characters (no test needed - visual only)
   - ⚠️  Debug visualization (not critical for production)

## 4. Automatisierte Pipeline-Tests / Automated Pipeline Tests

### 4.1 Bestehende Pipeline (build.yml)
- ✅ Script validation (parse error checking)
- ✅ Test suite execution
- ✅ Screenshot upload
- ✅ Android APK build
- ✅ Widget APK build
- ✅ Automated releases

### 4.2 Geplante Erweiterungen / Planned Extensions
- [ ] Code coverage reporting (GDScript Coverage Tool)
- [ ] Performance benchmarks
- [ ] Memory leak detection
- [ ] Static code analysis
- [ ] Security vulnerability scanning

## 5. Test-Infrastruktur / Test Infrastructure

### 5.1 Bestehend / Existing
- ✅ Test runner script (tests/run_tests.sh)
- ✅ Individual test timeout monitoring
- ✅ Screenshot helper for visual verification
- ✅ CI/CD integration with GitHub Actions
- ✅ Test scene templates

### 5.2 Zu implementieren / To Implement
- [ ] Code coverage tool integration
- [ ] Performance profiling integration
- [ ] Test data fixtures/factories
- [ ] Mock/stub utilities for isolation
- [ ] Test result dashboard/reporting

## 6. Test-Metriken / Test Metrics

### Aktuelle Abdeckung / Current Coverage
- **Unit Tests:** ~60% kritischer Systeme
- **Integration Tests:** ~50% kritischer Integrationen
- **Visual Tests:** ~70% UI-Komponenten
- **E2E Tests:** ~40% kritischer Szenarien

### Ziel-Abdeckung / Target Coverage
- **Unit Tests:** 90% kritischer Systeme
- **Integration Tests:** 80% kritischer Integrationen
- **Visual Tests:** 90% UI-Komponenten
- **E2E Tests:** 70% kritischer Szenarien

## 7. Test-Wartung / Test Maintenance

### Best Practices
1. Jede neue Funktion benötigt Tests
2. Tests vor Code schreiben (TDD wo möglich)
3. Tests müssen deterministisch sein
4. Tests müssen schnell sein (<1 Minute pro Test)
5. Tests müssen aussagekräftige Fehlermeldungen geben

### Code Review Checkliste
- [ ] Neue Funktionen haben Tests
- [ ] Alle Tests sind grün
- [ ] Keine übersprungenen/deaktivierten Tests ohne Begründung
- [ ] Test-Code folgt denselben Qualitätsstandards wie Produktionscode

## 8. Spezielle Überlegungen für Godot 4 / Special Considerations for Godot 4

### Headless Testing
- Godot 4 unterstützt --headless für CI/CD
- Visual tests können Screenshots generieren
- Physics müssen in Tests berücksichtigt werden (await frames)

### Android Spezifisch
- Mobile controls müssen auf Android getestet werden
- Touch input simulation in Tests
- Performance tests für mobile Geräte
- APK signature verification

### Seed-basierte Generierung
- Deterministisch durch Seeds
- Tests müssen Seeds verwenden für Reproduzierbarkeit
- Wichtig für Chunk Generation und Procedural Content

## 9. Fehlende Tests - Priorisierte Liste

### Sehr hohe Priorität
1. **test_world_manager.gd** - World chunk loading/unloading
2. **test_player.gd** - Complete player movement and physics
3. **test_npc.gd** - NPC AI and pathfinding
4. **test_quest_hook_system.gd** - Quest generation and tracking

### Hohe Priorität
5. **test_herb_system.gd** - Herb collection mechanics
6. **test_ui_manager.gd** - Complete UI state management
7. **test_save_corruption.gd** - Save file corruption handling
8. **test_player_world_integration.gd** - Player-world physics interaction

### Mittlere Priorität
9. **test_weather_system.gd** - Complete weather system (expand existing)
10. **test_procedural_models.gd** - Procedural model generation
11. **test_performance_benchmarks.gd** - Performance regression tests

## 10. Nächste Schritte / Next Steps

1. **Phase 1: Fehlende kritische Tests implementieren**
   - World Manager Tests
   - Player System Tests (erweitert)
   - NPC Tests
   - Quest System Tests

2. **Phase 2: Integration Tests erweitern**
   - Player-World Integration
   - Complete Game Loop
   - UI-State Synchronization

3. **Phase 3: Pipeline erweitern**
   - Code Coverage Integration
   - Performance Benchmarks
   - Security Scanning

4. **Phase 4: Dokumentation und Wartung**
   - Test Writing Guidelines
   - CI/CD Documentation
   - Maintenance Procedures

## 11. Ressourcen / Resources

### Tools
- Godot 4.3 Headless Mode
- GitHub Actions (CI/CD)
- Screenshot Helper (custom tool)
- GUT (Godot Unit Test) - optional consideration

### Dokumentation
- [Godot Testing Best Practices](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html)
- [tests/README.md](../tests/README.md)
- [DEVELOPMENT.md](../DEVELOPMENT.md)

---

**Letzte Aktualisierung:** 2026-02-02  
**Version:** 1.0  
**Verantwortlich:** Development Team
