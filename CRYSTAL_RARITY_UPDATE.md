# Crystal Rarity and Hidden Location Update

## Overview

This update implements the requirement to make crystals much rarer and spawn only in hidden locations, with rare crystals (Ruby and Sapphire) only appearing in unique mountain caves.

## Changes Made

### 1. Crystal System Configuration (`scripts/crystal_system.gd`)

**Growth Frequency Adjustments** (overall spawn rate reduction):
- Mountain Crystal: 0.4 → 0.15 (62.5% reduction)
- Emerald: 0.25 → 0.10 (60% reduction)
- Garnet: 0.20 → 0.08 (60% reduction)
- Amethyst: 0.18 → 0.07 (61% reduction)
- **Ruby: 0.05 → 0.005 (90% reduction)** - Extremely rare
- **Sapphire: 0.07 → 0.005 (93% reduction)** - Extremely rare

**Spawn Chance Adjustments** (type distribution when crystal spawns):
- Mountain Crystal: 35% (most common)
- Emerald: 30%
- Garnet: 20%
- Amethyst: 10%
- Ruby: 5% (only in unique mountain caves)
- Sapphire: 5% (only in unique mountain caves)

### 2. Chunk Crystal Placement (`scripts/chunk.gd`)

**Base Spawn Rate Changes:**
- Base spawn chance: 20% → 5% (75% reduction)
- Hidden valley spawn chance: New at 8%
- Cave spawn chance: New at 30% (for rare crystals in unique mountain)
- Crystals per rock: 1-2 → 1 (only one crystal per rock)

**Location-Based Spawning Logic:**
Crystals now only spawn in specific locations:

1. **Exposed Rocks (high elevation)**: No crystals at all
2. **Slightly Hidden Rocks**: 5% spawn chance (very rare)
3. **Deep Valley Rocks**: 8% spawn chance (rare)
4. **Regular Cave Rocks**: 8% spawn chance (rare)
5. **Unique Mountain Cave Rocks**: 30% spawn chance (common for this rare location)

**Rare Crystal Restrictions:**
- Ruby and Sapphire can ONLY spawn in unique mountain caves
- In unique mountain caves, there's a 60% chance to prefer rare crystals
- All other locations filter out rare crystals completely

## Impact

### Overall Rarity
- Crystals are approximately **4-10x rarer** than before
- Most rocks (those on hills and mountains) will never have crystals
- Players must explore valleys and caves to find crystals

### Rare Crystals (Ruby & Sapphire)
- Only spawn in the unique high mountain chunk caves (limited to 2-4 chunks globally)
- Approximately **10-20x rarer** than before due to:
  - 90%+ reduction in growth frequency
  - Location restrictions (only in specific caves)
  - Small number of valid locations in the world

### Common Crystals
- Spawn only in hidden locations (valleys and caves)
- No longer appear on easily accessible rocks
- Encourages exploration of lower terrain

## Technical Details

### Cave Detection
The system checks if a rock is inside a cave chamber by:
1. Iterating through all cave chambers in the chunk
2. Calculating distance from rock to chamber center
3. Checking if distance is less than chamber radius

### Unique Mountain Detection
- Only one unique mountain exists in the world
- Determined by chunk hash: `(hash % 73) == 42`
- Contains 3-5 caves with rare crystals
- Located within 900 units (~28 chunks) from spawn

## Testing Notes

To verify the changes work correctly:

1. **Common crystals in valleys**:
   - Explore low-lying areas
   - Check rocks in valleys
   - Should find Mountain Crystal, Emerald, Garnet, Amethyst occasionally

2. **No crystals on exposed rocks**:
   - Check rocks on hilltops and mountain slopes
   - Should never find crystals

3. **Rare crystals in unique mountain**:
   - Locate the unique high mountain (tallest in the world)
   - Enter caves (3-5 caves on the mountain)
   - Should find Ruby and Sapphire in cave rocks (30% spawn rate)
   - Approximately 60% of crystals in these caves should be rare types

## Expected Player Experience

Players will now:
- Need to actively search for crystals in hidden locations
- Explore valleys and lower terrain more thoroughly
- Seek out the unique mountain for rare crystals
- Find crystal collection more rewarding due to rarity
- Have approximately 2-4 chunks in the entire world where rare crystals can spawn

This creates a more treasure-hunt style gameplay loop where finding rare crystals is a significant achievement requiring exploration of the game's special locations.
