# Animated Figures Implementation

## Overview
This implementation adds animated characters to the game using the Universal Animation Library. Characters appear at key locations throughout the world:
- Around the starting location (3 characters)
- Near settlement buildings (30% chance per building, max 3 per chunk)
- Near lighthouses (80% chance per lighthouse)

## Files Added/Modified

### New Files
1. **assets/animations/character_animations.glb**
   - Universal Animation Library GLB file containing character model and animations
   - License: CC0 1.0 Universal (Public Domain)
   - Source: https://quaternius.com/animviewer.html

2. **scripts/animated_character.gd**
   - Main character controller script
   - Loads GLB model dynamically using GLTFDocument
   - Manages character states: IDLE, WALKING, WAVING
   - Handles animation playback based on available animations in GLB
   - Characters walk within a 3-unit radius of spawn point

3. **scenes/characters/animated_character.tscn**
   - Scene file for instantiating animated characters
   - References the animated_character.gd script

### Modified Files
1. **scripts/starting_location.gd**
   - Added NUM_ANIMATED_CHARACTERS constant (3 characters)
   - Added _create_animated_characters() function
   - Characters placed in a circle around the starting marker
   - Adjusted to terrain height after chunk loading

2. **scripts/chunk.gd**
   - Added AnimatedCharacter scene preload
   - Added constants for character placement:
     - ANIMATED_CHARACTER_SEED_OFFSET = 55555
     - ANIMATED_CHARACTER_CHANCE_NEAR_BUILDING = 0.3 (30%)
     - ANIMATED_CHARACTER_CHANCE_NEAR_LIGHTHOUSE = 0.8 (80%)
     - ANIMATED_CHARACTER_DISTANCE_FROM_BUILDING = 3.0
   - Added placed_buildings array to track buildings separately
   - Added placed_animated_characters array to track spawned characters
   - Added _place_animated_characters() to generation pipeline
   - Function places characters near buildings and lighthouses with terrain-aware positioning

## How It Works

### Character Loading
The AnimatedCharacter script dynamically loads the GLB file at runtime:
1. Uses GLTFDocument and GLTFState to parse the GLB file
2. Generates scene from GLTF data
3. Scales character to 0.5x for appropriate size
4. Finds AnimationPlayer node in loaded model
5. Maps character states to available animations

### Character Behavior
Characters have simple AI with three states:
- **IDLE**: Character stands in place (5 seconds)
- **WALKING**: Character walks randomly within 3-unit radius (3 seconds)
- **WAVING**: (Future feature - currently falls back to IDLE)

State transitions happen automatically with random variation for natural behavior.

### Placement Strategy
**Starting Location (scripts/starting_location.gd)**:
- 3 characters placed in circle around central marker
- Radius: ~60% of LOCATION_RADIUS (4.8-6.8 units from center)
- Fixed seed (123) ensures consistent placement across game sessions

**Near Buildings (scripts/chunk.gd)**:
- 30% chance per building to spawn a character
- Maximum 3 characters per chunk (prevents overcrowding)
- Characters placed 2-4 units from building
- Only on walkable terrain

**Near Lighthouses (scripts/chunk.gd)**:
- 80% chance per lighthouse to spawn a character
- Same distance and terrain rules as buildings
- Lighthouses are rarer, so higher spawn chance

## Testing the Implementation

### Visual Verification
When running the game:
1. **At Start**: Look around the starting location (central stone cairn with marker stones) - you should see 3 animated characters nearby
2. **In Settlements**: Travel to areas with buildings - some buildings should have characters standing or walking nearby
3. **At Lighthouses**: Find coastal lighthouses - most should have a character nearby

### Expected Behavior
- Characters should be standing or walking slowly
- They should stay on walkable terrain (not floating or underground)
- Walking characters should stay within ~3 units of spawn point
- Characters should automatically play animations from the GLB file

### Performance Considerations
- Characters are spawned only in loaded chunks (same as buildings)
- Characters use procedurally loaded GLB models (shared mesh data)
- Maximum ~3 characters per settlement chunk limits performance impact
- Starting location has fixed 3 characters

## Animation Library Details
The Universal Animation Library (UAL1_Standard.glb) includes multiple character animations:
- Idle/Stand animations
- Walk/Run animations  
- Various action animations (wave, jump, etc.)

The AnimatedCharacter script automatically detects available animations and maps them to states. To see all available animations, check the console output when a character spawns - it prints the animation list.

## Future Enhancements
Possible improvements:
1. Add more varied character behaviors (sitting, working, etc.)
2. Add character variation (different models/colors)
3. Make characters interactive (dialogue, quests)
4. Add NPC schedules (different positions at different times of day)
5. Add more animation states from the UAL library

## Troubleshooting

### Characters Not Appearing
- Check console for GLB loading errors
- Verify character_animations.glb exists in assets/animations/
- Ensure chunks are being generated (buildings/lighthouses exist)

### Characters Floating/Underground  
- Terrain height calculation should auto-adjust
- Check adjust_to_terrain() is being called

### No Animations Playing
- Check if GLB file contains AnimationPlayer node
- Verify animation names in console output
- Animation matching is case-insensitive

## License
The Universal Animation Library is licensed under CC0 1.0 Universal (Public Domain).
All implementation code follows the project's existing license.
