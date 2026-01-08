# Slope Limitation Fix - Inconsistent Behavior on Steep Edges

## Problem Statement (German)
> Steigung Begrenzung funktioniert jetzt manchmal. manchmal Stopt er an Steigungen manchmal geht er einfach hoch besonders an sehr steilen Kanten

**Translation**: Slope limitation now works sometimes. Sometimes it stops at slopes, sometimes it just goes up, especially at very steep edges.

## Root Cause Analysis

The previous implementation had several issues that caused inconsistent slope detection:

1. **Single-Point Check Too Close**: The slope was checked at only one position (`global_position + direction * move_speed * delta`), which is very close to the current position. At steep edges where the slope changes rapidly, this didn't provide enough warning.

2. **Frame-Rate Dependent**: The check distance was based on `delta`, making it vary with frame rate. Lower frame rates would check further ahead, higher frame rates closer - causing inconsistent behavior.

3. **Imprecise Gradient Calculation**: The gradient (direction of steepest ascent) was calculated using only 3 of the 4 heightmap cell corners, making it less accurate, especially at steep edges.

## Solution Implemented

### 1. Multi-Point Lookahead System

**File**: `scripts/player.gd`

Instead of checking a single point, the player now checks **three points** along the intended movement path:

```gdscript
@export var slope_check_near: float = 0.3   # Near check - about one step ahead
@export var slope_check_medium: float = 1.0 # Medium check - a few steps ahead
@export var slope_check_far: float = 2.5    # Far check - catch steep edges from a distance
```

Benefits:
- **Early Detection**: Catches steep edges before the player reaches them
- **Frame-Rate Independent**: Uses fixed world distances instead of delta-based calculations
- **Configurable**: Exported variables allow easy tuning without code changes
- **Efficient**: Uses early exit - stops checking as soon as a blocking slope is found

### 2. Improved Gradient Calculation

**File**: `scripts/chunk.gd`

The gradient calculation now uses proper central differences with all 4 corners of the heightmap cell:

```gdscript
# Old calculation (only 3 corners)
var dx = (h10 - h00) / CELL_SIZE
var dz = (h01 - h00) / CELL_SIZE

# New calculation (all 4 corners with proper central differences)
var dx = (h10 + h11 - h00 - h01) / (2.0 * CELL_SIZE)
var dz = (h01 + h11 - h00 - h10) / (2.0 * CELL_SIZE)
```

Benefits:
- **More Accurate**: Uses all available height information
- **Better Stability**: Central differences are more numerically stable
- **Handles Edges Better**: More robust at steep terrain transitions

### 3. Enhanced Test Coverage

**File**: `tests/test_slope_weather.gd`

Added validation for numerical stability:
- Checks for NaN (Not a Number) values
- Checks for infinite values
- Ensures gradient calculations remain valid

## How It Works

When the player tries to move:

1. **Calculate Movement Direction**: Get the normalized direction vector from input
2. **Check Multiple Points**: For each of the three lookahead distances:
   - Calculate position: `global_position + direction * check_distance`
   - Get slope at that position
   - If slope > 30°:
     - Get slope gradient (uphill direction)
     - Calculate dot product with movement direction
     - If dot product > 0.1 (moving significantly uphill): Block movement
3. **Allow or Block**: Movement is only blocked if moving uphill on a steep slope
   - Sideways movement: Allowed (dot product ≈ 0)
   - Downhill movement: Allowed (dot product < 0)
   - Uphill movement: Blocked (dot product > 0.1)

## Testing

The fix was tested with:
- Existing automated tests in `tests/test_slope_weather.gd`
- New checks for numerical stability (NaN/Inf validation)
- All tests validate:
  - Slope calculations return valid values (0-90 degrees)
  - Gradient calculations return valid Vector3 with y=0
  - Edge cases (positions outside chunks) return safe defaults

## Expected Behavior After Fix

### ✅ Should Work Correctly
- Player **stops** when trying to walk directly up a slope > 30°
- Player **can move** sideways along a steep slope
- Player **can move** downhill on any slope
- Steep edges are **detected early** before the player reaches them
- Behavior is **consistent** across different frame rates

### ❌ Previous Buggy Behavior (Now Fixed)
- ~~Sometimes player could walk up steep slopes~~
- ~~Sometimes player would stop at gentle slopes~~
- ~~Behavior varied based on frame rate~~
- ~~Steep edges were only detected when player was already on them~~

## Configuration

To tune the slope detection behavior, adjust these exported variables on the Player node:

- `max_slope_angle`: Maximum walkable slope in degrees (default: 30°)
- `slope_check_near`: Near lookahead distance (default: 0.3)
- `slope_check_medium`: Medium lookahead distance (default: 1.0)
- `slope_check_far`: Far lookahead distance (default: 2.5)

Larger lookahead distances will make the player stop earlier when approaching steep slopes.
Smaller lookahead distances will allow the player to get closer before being stopped.

## Files Modified

1. `scripts/player.gd` - Multi-point slope checking with configurable distances
2. `scripts/chunk.gd` - Improved gradient calculation using central differences
3. `tests/test_slope_weather.gd` - Enhanced test coverage for numerical stability

## Technical Notes

- The implementation maintains the existing gradient-based uphill detection
- No breaking changes to the API
- Fully backward compatible
- Performance impact: Minimal (3 slope checks instead of 1 per frame when moving)
- Memory impact: None (no new allocations)
