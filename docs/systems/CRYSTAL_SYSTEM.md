# Crystal Collection System

## Overview

The Crystal Collection System adds interactive collectible crystals that spawn on rocks throughout the procedurally generated world. Players can tap or click on crystals to collect them, with a counter displaying their inventory in the top-right corner of the screen.

## Features

### Crystal Types

Six different crystal types with unique colors and spawn rates:

1. **Mountain Crystal** (Clear/White)
   - Most common
   - Spawn chance: 35%
   - Growth frequency: 40%

2. **Emerald** (Green)
   - Uncommon
   - Spawn chance: 25%
   - Growth frequency: 25%

3. **Garnet** (Dark Red)
   - Uncommon
   - Spawn chance: 20%
   - Growth frequency: 20%

4. **Amethyst** (Purple)
   - Uncommon
   - Spawn chance: 20%
   - Growth frequency: 18%

5. **Ruby** (Bright Red)
   - Rare
   - Spawn chance: 8%
   - Growth frequency: 5%

6. **Sapphire** (Deep Blue)
   - Rare
   - Spawn chance: 7%
   - Growth frequency: 7%

### Visual Design

- **Shape**: Hexagonal prism crystals with pointed tops
- **Size Variation**: 0.8x to 1.5x base size
- **Material**: Transparent with emission for a magical glow
- **Placement**: 1-3 crystals per rock (35% chance a rock has crystals)

### Collection Mechanics

- **Desktop**: Click on crystals with left mouse button
- **Mobile**: Tap on crystals
- **Feedback**: Crystal animates upward and shrinks when collected
- **Raycast Detection**: Uses physics raycast for precise interaction

### UI Counter

- **Location**: Top-right corner of screen
- **Display**: Shows count for each crystal type with colored icons
- **Style**: Semi-transparent panel with rounded corners
- **Updates**: Real-time as crystals are collected

## Architecture

### Files

- `scripts/crystal_system.gd` - Core crystal system (static class)
- `scripts/chunk.gd` - Crystal spawning integration
- `scripts/player.gd` - Collection mechanics and inventory
- `scripts/ui_manager.gd` - Crystal counter UI

### Key Classes

#### CrystalSystem

Static class providing:
- Crystal type definitions and configurations
- Mesh generation for hexagonal crystal shapes
- Material creation with transparency and emission
- Random crystal type selection based on probabilities

```gdscript
# Example usage
var crystal_type = CrystalSystem.select_random_crystal_type(rng)
var mesh = CrystalSystem.create_crystal_mesh(crystal_type, 1.2, seed)
var material = CrystalSystem.create_crystal_material(crystal_type)
```

#### Chunk Integration

Crystals spawn during chunk generation:
1. Rocks are placed based on biome
2. Each rock has 35% chance to spawn crystals
3. 1-3 crystals placed around rock surface
4. Crystals positioned with random rotation and slight tilt

```gdscript
# In chunk.gd
func _place_crystals_on_rock(rock_instance: MeshInstance3D, rng: RandomNumberGenerator):
    if rng.randf() > CRYSTAL_SPAWN_CHANCE:
        return
    # Place 1-3 crystals on rock...
```

#### Player Inventory

Dictionary tracking collected crystals:

```gdscript
var crystal_inventory: Dictionary = {
    0: 0,  # MOUNTAIN_CRYSTAL
    1: 0,  # EMERALD
    2: 0,  # GARNET
    3: 0,  # RUBY
    4: 0,  # AMETHYST
    5: 0   # SAPPHIRE
}
```

Collection process:
1. Player taps/clicks screen
2. Raycast checks for crystal Area3D collision
3. Crystal removed with tween animation
4. Inventory updated
5. UI counter refreshed

## Configuration Constants

### Chunk.gd

```gdscript
const CRYSTAL_SEED_OFFSET = 54321
const CRYSTAL_SPAWN_CHANCE = 0.35  # 35% of rocks have crystals
const CRYSTALS_PER_ROCK_MIN = 1
const CRYSTALS_PER_ROCK_MAX = 3
```

### CrystalSystem.gd

Each crystal type has:
- `name`: Display name
- `color`: RGBA color with transparency
- `spawn_chance`: Weighted probability when selecting type
- `growth_frequency`: How often this type appears (informational)

## Testing

Run crystal system tests:

```bash
godot --headless res://tests/test_scene_crystal_system.tscn
```

Tests verify:
- Crystal type selection and distribution
- Mesh generation for all types
- Material creation with transparency
- Color uniqueness
- Spawn probability totals

## Performance Considerations

### Optimization

- **Low Poly Meshes**: ~50 vertices per crystal
- **Collision Detection**: Area3D with sphere shape for easy tapping
- **Spawn Limits**: Max 3 crystals per rock
- **No Physics**: Crystals are static decorations

### Memory Usage

- Each crystal: ~2KB (mesh + material + metadata)
- Typical chunk: 2-5 rocks with crystals = 6-15 crystals
- Impact: ~12-30KB per chunk with crystals

## Future Enhancements

Potential improvements:

- [ ] Crystal crafting system
- [ ] Crystal-powered abilities or upgrades
- [ ] Rare crystal variants (larger, different colors)
- [ ] Crystal mines or special spawn locations
- [ ] Trading system for crystals
- [ ] Achievements for collecting rare crystals
- [ ] Sound effects for collection
- [ ] Particle effects when collecting
- [ ] Save/load crystal inventory
- [ ] Daily/weekly crystal challenges

## Examples

### Creating a Custom Crystal

```gdscript
# Define custom crystal in CrystalSystem.crystal_configs
CrystalType.CUSTOM_CRYSTAL: {
    "name": "Custom Crystal",
    "color": Color(1.0, 0.5, 0.0, 0.9),  # Orange
    "spawn_chance": 0.10,
    "growth_frequency": 0.15
}
```

### Adjusting Spawn Rates

```gdscript
# In chunk.gd
const CRYSTAL_SPAWN_CHANCE = 0.50  # 50% of rocks have crystals (was 35%)
const CRYSTALS_PER_ROCK_MAX = 5    # Up to 5 crystals per rock (was 3)
```

### Accessing Player Inventory

```gdscript
# From another script
var player = get_tree().get_first_node_in_group("Player")
if player:
    var emerald_count = player.crystal_inventory[CrystalSystem.CrystalType.EMERALD]
    print("Emeralds collected: ", emerald_count)
```

## Integration with Existing Systems

### Chunk System
- Crystals spawn during `_place_rocks()` phase
- Seed-based reproducibility maintained
- Works with all biome types

### World Manager
- Crystals loaded/unloaded with chunks
- No special handling required

### Save System
- Currently not saved (enhancement opportunity)
- Easy to add via player save data

### UI System
- Counter uses existing UIManager
- Follows mobile-friendly design patterns
- Z-index ensures visibility

## Troubleshooting

### Crystals Not Spawning

Check:
1. `CRYSTAL_SPAWN_CHANCE` constant (should be 0.35)
2. Rocks are being placed in chunks
3. Console for any error messages

### Cannot Collect Crystals

Check:
1. Crystal has Area3D child with collision shape
2. Crystal is in "crystals" group
3. Player has camera reference
4. Input events are being processed

### UI Counter Not Updating

Check:
1. UIManager is in "UIManager" group
2. `update_crystal_count()` method exists
3. Player is calling the method after collection

### Performance Issues

If experiencing lag:
1. Reduce `CRYSTAL_SPAWN_CHANCE`
2. Reduce `CRYSTALS_PER_ROCK_MAX`
3. Check number of active chunks

## Technical Details

### Collision Detection

Crystals use Area3D nodes for interaction:
- SphereShape3D collision (radius: 0.3 * size_scale)
- Slightly larger than visual for easier mobile tapping
- No physics computation needed

### Mesh Generation

Hexagonal prism algorithm:
1. Create bottom hexagon vertices
2. Create top hexagon vertices (rotated, smaller)
3. Generate side faces connecting bottom to top
4. Create pyramid top from top hexagon to apex
5. Apply vertex colors with slight variation per facet

### Material Properties

StandardMaterial3D settings:
- `transparency`: ALPHA mode for see-through effect
- `emission`: Crystal color * 0.3 for glow
- `metallic`: 0.2
- `roughness`: 0.2 (shiny)
- `vertex_color_use_as_albedo`: true

## Version History

- **v1.0.53** (2026-01-17)
  - Initial crystal collection system
  - 6 crystal types with unique colors
  - Mobile tap and desktop click collection
  - Top-right counter UI
  - Test suite for crystal system

---

**Last Updated**: 2026-01-17
**Author**: Copilot Agent
**Related Systems**: Chunk System, Player, UI Manager
