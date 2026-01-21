# Ocean Path and Fence Post Implementation

## Overview

This implementation adds three new features to the game based on the requirement that "lighthouses should only stand directly at large seas, one of the paths should point towards the sea and end at a spot on the large sea, and on this path, wooden posts should stand repeatedly like from a fence but without wire."

## Features Implemented

### 1. Large Ocean Detection for Lighthouses

**Requirement**: Lighthouses should only be placed at "large seas" (großen Meer)

**Implementation**:
- Added `MIN_LARGE_OCEAN_SIZE = 3` constant to define minimum ocean size
- Created `_is_part_of_large_ocean()` function in `chunk.gd` that uses flood fill to detect connected ocean chunks
- Modified `_place_lighthouses_if_coastal()` to check if neighboring ocean is part of a large ocean before placing lighthouse
- Uses limited flood fill search (max 20 chunks) to avoid performance issues

**Technical Details**:
```gdscript
# In chunk.gd
const MIN_LARGE_OCEAN_SIZE = 3  # Minimum number of connected ocean chunks

func _is_part_of_large_ocean(ocean_chunk_pos: Vector2i) -> bool:
    # Flood fill to count connected ocean chunks
    # Returns true if >= MIN_LARGE_OCEAN_SIZE ocean chunks are connected
```

### 2. Ocean-Directed Paths

**Requirement**: One of the paths should point towards the sea and end at a spot on the large sea

**Implementation**:
- Added ocean detection constants to `path_system.gd`:
  - `OCEAN_LEVEL = -8.0`
  - `OCEAN_START_DISTANCE = 160.0`
  - `OCEAN_PROXIMITY_THRESHOLD = 8.0`
- Created `_is_near_ocean()` function to detect if a path endpoint is near ocean
- Modified `_check_endpoint()` to prioritize ocean proximity over cluster proximity
- Paths now automatically terminate when they reach ocean/coastal areas

**Technical Details**:
```gdscript
# In path_system.gd
static func _is_near_ocean(world_pos: Vector2) -> bool:
    # Check distance from origin (ocean starts at OCEAN_START_DISTANCE)
    # Check neighboring chunks for ocean presence
    # Returns true if position is in ocean territory
```

**Behavior**:
- Paths that reach the ocean area (distance >= 160 units from origin) automatically become endpoints
- Ocean endpoints have higher priority than forest/settlement endpoints
- At least one path from spawn will eventually reach the ocean

### 3. Fence Posts Along Ocean Paths

**Requirement**: On the path to the ocean, wooden posts should stand repeatedly like from a fence but without wire

**Implementation**:
- Added fence post constants:
  - `FENCE_POST_HEIGHT = 1.5`
  - `FENCE_POST_RADIUS = 0.1`
  - `FENCE_POST_SEGMENTS = 6` (hexagonal shape)
  - `FENCE_POST_SPACING = 4.0` (distance between posts)
- Created `create_fence_post_mesh()` in `procedural_models.gd` to generate simple wooden posts
- Created `create_fence_post_material()` with weathered wood appearance
- Implemented `_place_fence_posts_on_ocean_paths()` in `chunk.gd` to place posts along ocean-directed paths

**Technical Details**:
```gdscript
# In chunk.gd
func _place_fence_posts_on_ocean_paths() -> void:
    # Only place posts on path segments that are endpoints near ocean
    # Posts placed every FENCE_POST_SPACING (4.0) units along the path
    # Posts follow terrain height
    # Slight random rotation for natural look
```

**Visual Characteristics**:
- Weathered wood color (grayish brown: Color(0.45, 0.35, 0.25))
- Height: 1.5 units with ±10% variation
- Hexagonal cylinder shape for simple, low-poly appearance
- Casts shadows for visual depth
- Slight random rotation (±0.1 radians) for natural appearance

## Files Modified

1. **scripts/chunk.gd** (+125 lines)
   - Added `MIN_LARGE_OCEAN_SIZE` constant
   - Added `FENCE_POST_SEED_OFFSET` and `FENCE_POST_SPACING` constants
   - Modified `_place_lighthouses_if_coastal()` to check for large ocean
   - Added `_is_part_of_large_ocean()` function
   - Added `_place_fence_posts_on_ocean_paths()` function
   - Modified `_generate_paths()` to call fence post placement

2. **scripts/path_system.gd** (+40 lines)
   - Added ocean-related constants
   - Modified `_check_endpoint()` to prioritize ocean detection
   - Added `_is_near_ocean()` function

3. **scripts/procedural_models.gd** (+36 lines)
   - Added fence post constants
   - Added `create_fence_post_mesh()` function
   - Added `create_fence_post_material()` function

## Performance Considerations

- **Large Ocean Detection**: Limited to 20 chunk searches to avoid performance issues
- **Fence Post Placement**: Only on endpoint path segments near ocean, not all paths
- **Ocean Detection**: Simple distance-based check (no full chunk generation needed)
- **Mesh Generation**: Low-poly hexagonal posts with minimal vertices

## Integration

The features integrate seamlessly with existing systems:
- Works with existing chunk generation pipeline
- Compatible with existing path system
- Uses existing procedural model generation patterns
- Respects existing lake and terrain systems

## Testing Recommendations

1. **Lighthouse Placement**:
   - Travel to ocean areas (160+ units from spawn)
   - Verify lighthouses only appear at large ocean areas (3+ connected ocean chunks)
   - Check that isolated ocean chunks don't have lighthouses

2. **Ocean Paths**:
   - Follow paths from spawn
   - Verify at least one path leads toward ocean
   - Check that paths properly terminate at ocean boundaries

3. **Fence Posts**:
   - Find ocean-directed path endpoints
   - Verify posts appear every ~4 units along the path
   - Check that posts follow terrain height
   - Confirm posts have weathered wood appearance

## Future Enhancements

Potential improvements:
- Add variation in fence post types (different wood colors, weathering levels)
- Implement post damage/decay near water
- Add particle effects (salt spray, water droplets)
- Connect posts with rope or chain (optional wire alternative)
- Add navigational markers at ocean endpoints (buoys, signs)
