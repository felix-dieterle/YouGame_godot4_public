# Directional Terrain Gradient Implementation

## Problem Statement (German)
> können wir Richtung mehr ein leichtes stetiges Gefälle haben

**Translation**: Can we have a slight steady gradient/slope in one direction

## Solution Implemented

Added a subtle directional gradient to the terrain generation to create a gentle slope across the world.

### Key Changes

**File**: `scripts/chunk.gd`

#### 1. Added Configuration Constants

```gdscript
# Directional gradient constants
const GRADIENT_DIRECTION = Vector2(0, 1)  # Direction of terrain slope (Z-axis / north)
const GRADIENT_STRENGTH = 0.015  # Subtle gradient: 0.015 units per world unit = ~0.86° slope
```

- **GRADIENT_DIRECTION**: Vector2(0, 1) creates a slope towards the positive Z-axis (north in the game world)
- **GRADIENT_STRENGTH**: 0.015 units per world unit creates a very gentle ~0.86° slope
  - This is well below the MAX_SLOPE_WALKABLE (30°) threshold
  - Over 100 units of distance, the elevation changes by only 1.5 units
  - Subtle enough to feel natural but noticeable over long distances

#### 2. Modified Heightmap Generation

In `_generate_heightmap()`:

```gdscript
# Calculate base height from noise
var height = noise.get_noise_2d(world_x, world_z) * height_multiplier + height_offset

# Add subtle directional gradient
var gradient_offset = (world_x * GRADIENT_DIRECTION.x + world_z * GRADIENT_DIRECTION.y) * GRADIENT_STRENGTH
height += gradient_offset

heightmap[z * (RESOLUTION + 1) + x] = height
```

#### 3. Updated Height Estimation

In `_get_estimated_chunk_height()` - applied the same gradient calculation to maintain consistency for ocean detection and other height-based systems.

## Technical Details

### How It Works

The directional gradient is calculated as a dot product:
- `gradient_offset = (world_x * GRADIENT_DIRECTION.x + world_z * GRADIENT_DIRECTION.y) * GRADIENT_STRENGTH`
- For GRADIENT_DIRECTION = Vector2(0, 1): `gradient_offset = world_z * 0.015`
- This means the terrain gradually rises as you move north (positive Z direction)

### Impact on Gameplay

1. **Gentle Slope**: The terrain now has a consistent, barely perceptible slope towards the north
2. **Walkability Preserved**: The gradient is subtle enough (< 1°) that it doesn't affect the walkability system
3. **Biome Variation Maintained**: The gradient is additive, so all biome variations (mountains, valleys, etc.) remain intact
4. **Ocean Generation**: Updated to account for the gradient when determining ocean biomes

### Configuration

To adjust the gradient:

- **Change Direction**: Modify `GRADIENT_DIRECTION`
  - Vector2(1, 0): Slope towards east
  - Vector2(-1, 0): Slope towards west
  - Vector2(0, -1): Slope towards south
  - Vector2(1, 1).normalized(): Slope towards northeast (diagonal)
  
- **Change Steepness**: Modify `GRADIENT_STRENGTH`
  - Smaller values: More subtle slope
  - Larger values: Steeper slope
  - Recommended range: 0.01 to 0.03 to keep within playable limits

### Slope Calculation

- Gradient strength: 0.015 units/world unit
- Angle: arctan(0.015) ≈ 0.86°
- Over 32 units (one chunk): ~0.48 units elevation change
- Over 100 units (~3 chunks): ~1.5 units elevation change
- This is very subtle and provides a gentle "flow" to the landscape

## Testing

The changes maintain compatibility with existing systems:
- ✅ Walkability calculations still work correctly (gradient well below 30° threshold)
- ✅ Ocean biome detection updated to account for gradient
- ✅ Chunk blending continues to work (gradient is continuous across chunk boundaries)
- ✅ Height-based systems (lakes, lighthouses, etc.) work as before

## Files Modified

- `scripts/chunk.gd` - Added gradient constants and applied to height generation

## Backward Compatibility

The changes are fully backward compatible:
- Existing save files will work (different terrain due to new generation, but no structural changes)
- All APIs remain unchanged
- No breaking changes to any systems
