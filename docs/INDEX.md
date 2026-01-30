# YouGame Documentation Index

This index helps you navigate all documentation in the repository.

## 🚀 Getting Started

Start here if you're new to the project:

1. **[README.md](../README.md)** - Project overview and introduction
2. **[QUICKSTART.md](../QUICKSTART.md)** - Quick setup and first run
3. **[DEVELOPMENT.md](../DEVELOPMENT.md)** - Development practices and guidelines
4. **[FEATURES.md](../FEATURES.md)** - Feature overview

## 🤖 For AI Agents

**Start here for AI-assisted development:**

- **[.github/instructions/PROJECT_GUIDE.md](../.github/instructions/PROJECT_GUIDE.md)** - Comprehensive AI agent guide
  - Architecture overview
  - Code conventions
  - Performance guidelines
  - Common patterns and anti-patterns
  - Quick navigation tips

## 📚 Core Documentation (Root Level)

### Essential Guides
- **[README.md](../README.md)** - Project introduction and architecture
- **[DEVELOPMENT.md](../DEVELOPMENT.md)** - Development workflow and practices
- **[QUICKSTART.md](../QUICKSTART.md)** - Setup and getting started
- **[QUICK_REFERENCE.md](../QUICK_REFERENCE.md)** - Command and API quick reference
- **[FEATURES.md](../FEATURES.md)** - Feature list and descriptions

## 🔧 System Documentation (docs/systems/)

Deep dives into each major system:

- **[CLUSTER_SYSTEM.md](systems/CLUSTER_SYSTEM.md)** - Cross-chunk object placement system
- **[DAY_NIGHT_CYCLE.md](systems/DAY_NIGHT_CYCLE.md)** - Time of day and lighting system
- **[DEBUG_OVERLAY_SYSTEM.md](systems/DEBUG_OVERLAY_SYSTEM.md)** - Debug UI and logging
- **[NARRATIVE_SYSTEM.md](systems/NARRATIVE_SYSTEM.md)** - Narrative markers and quest generation
- **[OCEAN_LIGHTHOUSE_SYSTEM.md](systems/OCEAN_LIGHTHOUSE_SYSTEM.md)** - Ocean biome and coastal lighthouses
- **[PATH_SYSTEM.md](systems/PATH_SYSTEM.md)** - Path generation across terrain
- **[SAVE_LOAD_SYSTEM.md](systems/SAVE_LOAD_SYSTEM.md)** - Save and load functionality
- **[TERRAIN_RENDERING.md](systems/TERRAIN_RENDERING.md)** - Terrain generation and rendering

## 💻 Code Documentation

- **[scripts/README.md](../scripts/README.md)** - Complete guide to all 31 scripts
  - Organized directory structure
  - Quick reference by category
  - Key algorithms explained
  - Code patterns and examples
  - Common extension patterns
- **[SCRIPT_REORGANIZATION.md](SCRIPT_REORGANIZATION.md)** - Script consolidation guide
  - Before/after structure comparison
  - Migration guide for path changes
  - System categorization details

## 🛠️ Supporting Documentation (docs/)

- **[ASSET_GUIDE.md](ASSET_GUIDE.md)** - Asset management and credits
- **[ASSET_CREDITS_TEMPLATE.md](ASSET_CREDITS_TEMPLATE.md)** - Template for asset attribution
- **[DEBUG_README.md](DEBUG_README.md)** - Debugging tools and techniques
- **[MOBILE_MENU.md](MOBILE_MENU.md)** - Mobile UI and controls
- **[QUICK_SAVE.md](QUICK_SAVE.md)** - Quick save/load details
- **[TEST_SCREENSHOTS.md](TEST_SCREENSHOTS.md)** - Testing and screenshots

## 📦 Historical Documentation (docs/archive/)

Implementation notes and historical context from previous development. Useful for understanding why certain decisions were made:

### Implementation Summaries
- IMPLEMENTATION.md
- IMPLEMENTATION_COMPLETE.md
- IMPLEMENTATION_SUMMARY.md
- IMPLEMENTATION_NARRATIVE.md
- IMPLEMENTATION_SAVE_LOAD.md
- IMPLEMENTATION_DEBUG_OVERLAY.md
- And many more...

### Fix Documentation
- Multiple fix summaries for various features
- Visual guides for UI changes
- Bug fix documentation

**Note:** Archive files are historical references. For current implementation, refer to the main system docs above.

## 🔍 Finding What You Need

### By Task

**Setting up the project?**
→ [QUICKSTART.md](../QUICKSTART.md)

**Understanding the architecture?**
→ [.github/instructions/PROJECT_GUIDE.md](../.github/instructions/PROJECT_GUIDE.md) or [README.md](../README.md)

**Working on a specific system?**
→ Check [docs/systems/](systems/) for system-specific docs

**Need to understand a script?**
→ [scripts/README.md](../scripts/README.md)

**Debugging issues?**
→ [DEBUG_README.md](DEBUG_README.md) and [docs/systems/DEBUG_OVERLAY_SYSTEM.md](systems/DEBUG_OVERLAY_SYSTEM.md)

**Building for Android?**
→ [DEVELOPMENT.md](../DEVELOPMENT.md) (Building section)

**AI agent development?**
→ [.github/instructions/PROJECT_GUIDE.md](../.github/instructions/PROJECT_GUIDE.md)

### By System

| System | Script Files | Documentation |
|--------|-------------|---------------|
| **World/Terrain** | systems/world/world_manager.gd, systems/world/chunk.gd | [TERRAIN_RENDERING.md](systems/TERRAIN_RENDERING.md) |
| **Objects** | systems/world/cluster_system.gd, systems/world/procedural_models.gd | [CLUSTER_SYSTEM.md](systems/CLUSTER_SYSTEM.md) |
| **Paths** | systems/world/path_system.gd | [PATH_SYSTEM.md](systems/PATH_SYSTEM.md) |
| **Narrative** | systems/quest/narrative_marker.gd, systems/quest/quest_hook_system.gd | [NARRATIVE_SYSTEM.md](systems/NARRATIVE_SYSTEM.md) |
| **Player** | systems/character/player.gd, ui/mobile_controls.gd | [DEVELOPMENT.md](../DEVELOPMENT.md) |
| **NPCs** | systems/character/npc.gd | [DEVELOPMENT.md](../DEVELOPMENT.md) |
| **Day/Night** | systems/environment/day_night_cycle.gd, systems/environment/weather_system.gd | [DAY_NIGHT_CYCLE.md](systems/DAY_NIGHT_CYCLE.md) |
| **UI** | ui/ui_manager.gd, ui/pause_menu.gd | [MOBILE_MENU.md](MOBILE_MENU.md) |
| **Debug** | debug/debug_log_overlay.gd, debug/debug_visualization.gd | [DEBUG_OVERLAY_SYSTEM.md](systems/DEBUG_OVERLAY_SYSTEM.md) |
| **Save/Load** | utilities/save_game_manager.gd | [SAVE_LOAD_SYSTEM.md](systems/SAVE_LOAD_SYSTEM.md) |
| **Collection** | systems/collection/crystal_system.gd, systems/collection/herb_system.gd | [scripts/systems/collection/README.md](../scripts/systems/collection/README.md) |

### By Topic

**Performance Optimization**
- [.github/instructions/PROJECT_GUIDE.md](../.github/instructions/PROJECT_GUIDE.md) - Performance Guidelines section
- [scripts/README.md](../scripts/README.md) - Performance Patterns section
- [DEVELOPMENT.md](../DEVELOPMENT.md) - Performance Optimizations section

**Code Conventions**
- [.github/instructions/PROJECT_GUIDE.md](../.github/instructions/PROJECT_GUIDE.md) - Code Conventions section
- [scripts/README.md](../scripts/README.md) - Code Style Patterns section

**Testing**
- [.github/instructions/PROJECT_GUIDE.md](../.github/instructions/PROJECT_GUIDE.md) - Testing Guidelines section
- [DEVELOPMENT.md](../DEVELOPMENT.md) - Testing section
- [TEST_SCREENSHOTS.md](TEST_SCREENSHOTS.md)

**Building & Deployment**
- [DEVELOPMENT.md](../DEVELOPMENT.md) - Building section
- [QUICKSTART.md](../QUICKSTART.md) - Setup instructions

## 📝 Document Maintenance

### When to Update Documentation

1. **Adding a new feature:** Update relevant system doc in docs/systems/
2. **Adding a new script:** Update scripts/README.md
3. **Changing architecture:** Update .github/instructions/PROJECT_GUIDE.md
4. **Fixing bugs:** Consider adding to archive if it explains important decisions
5. **Changing version:** Update DEVELOPMENT.md and PROJECT_GUIDE.md

### Documentation Standards

- Use clear, concise language
- Include code examples where helpful
- Keep AI agents in mind (be explicit, not implicit)
- Cross-reference related docs
- Update "Last Updated" dates

## 🎯 Quick Links

- **Project Repository:** GitHub (check remote origin)
- **Godot Docs:** https://docs.godotengine.org/en/stable/
- **GDScript Reference:** https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/

---

**Last Updated:** 2026-01-15  
**Godot Version:** 4.3  
**Project Version:** 1.0.52
