# Character Systems

Player and NPC character controllers and animation systems.

## Files

### Player (`player.gd`)
- Player character controller with dual camera system
- Third-person and first-person camera modes (toggle with V)
- Movement with terrain following
- Joystick/keyboard controls support
- Crystal, torch, and campfire placement
- Sprint and jetpack mechanics

### NPC (`npc.gd`)
- NPC AI with state machine
- States: IDLE, WALKING
- Random movement and idle behavior
- Terrain snapping
- Constants: `WALK_SPEED = 2.0`, `IDLE_TIME_MIN/MAX`

### Animated Character (`animated_character.gd`)
- Character animation state management
- Handles animation blending
- Integrates with character movement

## Usage

```gdscript
# Player is typically added in main scene
var player = Player.new()
add_child(player)

# NPCs are spawned by narrative system
var npc = NPC.new()
npc.position = spawn_point
add_child(npc)
```

## Integration

- Player interacts with collection systems (crystals, herbs, torches)
- NPCs are managed by quest/narrative systems
- Both use chunk terrain data for height snapping
