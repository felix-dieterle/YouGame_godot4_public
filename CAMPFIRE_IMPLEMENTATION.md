# Inventory Items and Campfire Implementation

## Overview

This document describes the implementation of new inventory items and the campfire creation system for YouGame.

## Requirements (German → English)

Original requirements in German:
> 2 Feuersteine im Inventar, wenn die benutzt werden per Aktion entsteht am Boden ein brennendes Lagerfeuer, Trinkflasche mit füllgrad im Inventar, Pilze im inventar

Translation:
- 2 flint stones in inventory - when used via action, creates a burning campfire on the ground
- Drinking bottle with fill level in inventory
- Mushrooms in inventory

## Implementation

### 1. New Inventory Items

#### Flint Stones (Feuersteine)
- **Initial count**: 2
- **Variable**: `flint_stone_count: int`
- **Usage**: Press 'C' key to use 2 flint stones and create a campfire
- **Save/Load**: Persists across game sessions

#### Mushrooms (Pilze)
- **Initial count**: 0
- **Variable**: `mushroom_count: int`
- **Save/Load**: Persists across game sessions

#### Water Bottle (Trinkflasche)
- **Initial fill level**: 100%
- **Variable**: `bottle_fill_level: float` (0.0 - 100.0)
- **Save/Load**: Persists across game sessions

### 2. Campfire System

#### Campfire Creation
- **Input**: Press 'C' key (use_flint_stones action)
- **Cost**: 2 flint stones
- **Location**: Created at player's current position

#### Campfire Features
- **Visual Components**:
  - Stone circle base (6 stones arranged in a circle)
  - Wood logs in center (3 logs)
  - Bright fire effect (glowing sphere)
  - OmniLight3D for illumination

- **Lighting**:
  - Energy: 8.0 (brighter than torches at 5.0)
  - Range: 40.0 units (farther than torches at 30.0)
  - Attenuation: 0.8
  - Color: Warm orange (1.0, 0.6, 0.2)

- **Save/Load**: Campfire positions persist across game sessions

### 3. Code Changes

#### New Files
1. **scripts/campfire_system.gd**
   - `create_campfire_node()` - Creates a campfire with visual and lighting components
   - Similar structure to `torch_system.gd`

2. **tests/test_campfire_system.gd**
   - Comprehensive test suite for new features
   - Tests property existence, campfire creation, and save/load functionality

#### Modified Files
1. **scripts/player.gd**
   - Added inventory variables: `flint_stone_count`, `mushroom_count`, `bottle_fill_level`
   - Added `_use_flint_stones()` function for campfire creation
   - Updated `_load_saved_state()` to restore new inventory items

2. **scripts/ui_manager.gd**
   - Added UI labels for new inventory items
   - Added update functions: `update_flint_stone_count()`, `update_mushroom_count()`, `update_bottle_fill_level()`
   - Updated inventory panel with new item displays

3. **scripts/save_game_manager.gd**
   - Extended save_data structure with new inventory items
   - Added ConfigFile save operations for new items
   - Added ConfigFile load operations with proper defaults
   - Added campfires array to world data

4. **project.godot**
   - Added `use_flint_stones` input action mapped to 'C' key

### 4. Usage Instructions

#### Viewing Inventory
1. Press 'I' to open inventory panel
2. View current counts for:
   - Torches
   - Flint Stones
   - Mushrooms
   - Water Bottle (with percentage)

#### Creating a Campfire
1. Ensure you have at least 2 flint stones
2. Press 'C' key
3. Campfire is created at your current position
4. Flint stone count decreases by 2

#### Messages
- Success: "Campfire created! (X flint stones left)"
- Failure: "Need 2 flint stones to create campfire! (X/2)"

## Testing

### Test Suite
Run the test suite to verify implementation:
```bash
./run_tests.sh test_scene_campfire_system.tscn
```

### Manual Testing
1. Start game
2. Press 'I' to view inventory (should show 2 flint stones, 0 mushrooms, 100% water bottle)
3. Press 'C' to create a campfire
4. Verify campfire appears with fire and lighting
5. Press 'I' to verify flint stone count decreased to 0
6. Save and reload game to verify persistence

## Technical Notes

### Design Patterns
- Follows existing torch system pattern
- Uses ConfigFile for save/load operations
- Integrates with existing UI system
- Uses Godot's group system for scene management ("Campfires" group)

### Performance
- Minimal overhead (similar to torch system)
- Efficient save/load using JSON for arrays
- No impact on gameplay performance

## Future Enhancements

Potential future improvements:
- Add mushroom collection mechanic
- Implement water bottle consumption and refilling
- Add campfire animation (flickering flames)
- Add cooking mechanic using campfires
- Add campfire fuel/duration system
