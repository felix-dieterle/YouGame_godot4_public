# Collection Systems

Resource collection and placement systems for the game world.

## Files

### Crystal System (`crystal_system.gd`)
- Manages 6 crystal types with unique colors and spawn rates
- Generates hexagonal crystal meshes procedurally
- Creates transparent materials with emission glow
- Used by chunks for crystal spawning on rocks
- Crystals: Mountain Crystal, Emerald, Garnet, Ruby, Amethyst, Sapphire

### Herb System (`herb_system.gd`)
- Manages herb collection mechanics
- Restores 30% health when collected
- Procedural herb placement in walkable areas

### Torch System (`torch_system.gd`)
- Creates placeable torches with lighting
- Light energy: 5.0, Range: 30m
- Used for player-placed illumination

### Campfire System (`campfire_system.gd`)
- Creates campfires with enhanced lighting
- Light energy: 8.0, Range: 40m
- Rest points for players

## Usage

All systems are static utility classes that provide procedural generation:

```gdscript
# Crystal placement
const CrystalSystem = preload("res://scripts/systems/collection/crystal_system.gd")
var crystal = CrystalSystem.create_crystal(position, crystal_type)

# Herb placement
const HerbSystem = preload("res://scripts/systems/collection/herb_system.gd")
var herb = HerbSystem.create_herb(position)

# Torch placement
const TorchSystem = preload("res://scripts/systems/collection/torch_system.gd")
var torch = TorchSystem.create_torch(position)
```

## Integration

These systems are called by `chunk.gd` during terrain generation to place collectible resources in the world.
