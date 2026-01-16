# Robot Character Design

## Overview
The player character has been transformed from a simple capsule into a small robot with visible features.

## Robot Components

### Body Structure
1. **Main Torso**: Dark gray metallic box (0.8 × 1.0 × 0.6 units)
   - Position: Center of character
   - Material: Dark gray (#4D4D59) with metallic finish (0.7 metallic, 0.3 roughness)

2. **Head**: Lighter gray box (0.6 × 0.5 × 0.5 units)
   - Position: On top of body at 1.25 units height
   - Material: Lighter gray (#666673) with metallic finish (0.6 metallic, 0.4 roughness)

3. **Eyes**: Two glowing cyan spheres (0.12 radius each)
   - Position: Front of head, spaced 0.3 units apart
   - Left eye: (-0.15, 1.3, 0.25)
   - Right eye: (0.15, 1.3, 0.25)
   - Material: Cyan (#33CCFF) with emission (energy: 2.0)
   - **Purpose**: Shows which direction the robot is facing

4. **Antenna**: Red metallic cylinder (0.3 height, 0.03 radius)
   - Position: Top of head at 1.65 units height
   - Material: Red (#CC3333) with high metallic (0.9)

5. **Antenna Tip**: Small glowing red sphere (0.08 radius)
   - Position: Top of antenna at 1.8 units height
   - Material: Bright red (#FF4D4D) with emission (energy: 1.5)

## Directional Visibility
The glowing cyan eyes are positioned at the **front** of the robot's head (positive Z direction), making it easy to see which direction the robot is facing. As the robot rotates during movement, the eyes clearly indicate the facing direction.

## Height and Positioning
- Total robot height: ~1.8 units
- Character controller offset: 1.0 unit above terrain (to keep robot above ground)
- Eyes positioned prominently at 1.3 units for clear visibility

## Interaction with Environment
The robot maintains all original movement behaviors:
- Rotates smoothly toward movement direction
- Snaps to terrain height
- Works with both keyboard and mobile controls
- Camera follows robot from behind and above

The metallic materials ensure the robot receives proper lighting and shadows from the environment, making it stand out against the terrain.
