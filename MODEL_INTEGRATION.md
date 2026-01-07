# Model Integration Guide

This guide explains the easiest way to integrate free 3D models into the YouGame project.

## Supported Model Formats

Godot 4 natively supports the following 3D model formats:
- **glTF 2.0** (.gltf, .glb) - **RECOMMENDED** - Industry standard, best compatibility
- **.blend** (Blender files) - Direct import if Blender is installed
- **.dae** (Collada)
- **.obj** (Wavefront OBJ)

## Where to Find Free Models

Popular sources for free 3D models:
1. **Polyhaven** (polyhaven.com) - CC0 licensed, high quality
2. **Sketchfab** (sketchfab.com) - Filter by "Downloadable" and "Free"
3. **OpenGameArt** (opengameart.org) - Game-ready assets
4. **Kenney Assets** (kenney.nl) - Low-poly game assets, CC0 license
5. **Quaternius** (quaternius.com) - Low-poly characters and assets, CC0

## Step-by-Step Integration

### 1. Download and Prepare Model

1. Download your model in **.glb** or **.gltf** format (preferred)
2. If not available, convert to glTF using Blender:
   - File → Import → Your format (.fbx, .obj, etc.)
   - File → Export → glTF 2.0 (.glb)

### 2. Import into Godot

1. Create an `assets/models/` folder in your project if it doesn't exist
2. Copy your model file into this folder
3. Godot will automatically import it - wait for the import to complete
4. Check the "Import" tab (next to Scene tab) for any import errors

### 3. Replace Player Character

To replace the robot character with a custom model:

```gdscript
# In scripts/player.gd, modify _create_robot_body():

func _create_robot_body():
	# Load your custom model
	var model_scene = load("res://assets/models/your_character.glb")
	var model_instance = model_scene.instantiate()
	
	# Scale if needed
	model_instance.scale = Vector3(1.0, 1.0, 1.0)
	
	# Adjust position (model origin might differ)
	model_instance.position = Vector3(0, 0, 0)
	
	add_child(model_instance)
	robot_parts.append(model_instance)
```

### 4. Add Static Models to Terrain

To place decorative objects on the terrain:

```gdscript
# In scripts/chunk.gd, add to the generate() function:

func generate():
	_setup_noise()
	_generate_heightmap()
	_calculate_walkability()
	_ensure_walkable_area()
	_calculate_metadata()
	_generate_lake_if_valley()
	_create_mesh()
	_place_decorative_objects()  # Add this line

# Add this new function:
func _place_decorative_objects():
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(chunk_x, chunk_z)) + seed_value
	
	# Load your model
	var tree_model = load("res://assets/models/tree.glb")
	
	# Place 3-5 objects randomly on walkable terrain
	var object_count = rng.randi_range(3, 5)
	for i in range(object_count):
		var x = rng.randf_range(0, CHUNK_SIZE)
		var z = rng.randf_range(0, CHUNK_SIZE)
		
		# Check if position is walkable
		var cell_x = int(x / CELL_SIZE)
		var cell_z = int(z / CELL_SIZE)
		if cell_x >= 0 and cell_x < RESOLUTION and cell_z >= 0 and cell_z < RESOLUTION:
			if walkable_map[cell_z * RESOLUTION + cell_x] == 1:
				var height = get_height_at_world_pos(
					chunk_x * CHUNK_SIZE + x,
					chunk_z * CHUNK_SIZE + z
				)
				
				var model_instance = tree_model.instantiate()
				model_instance.position = Vector3(x, height, z)
				
				# Random rotation for variety
				model_instance.rotation.y = rng.randf_range(0, 2 * PI)
				
				add_child(model_instance)
```

## Tips for Best Results

### Performance Optimization
- Use **low-poly models** (< 5000 triangles per object) for mobile compatibility
- Enable **LOD (Level of Detail)** for distant objects
- Use texture atlases to reduce draw calls

### Scale Adjustment
If your model appears too large/small:
```gdscript
model_instance.scale = Vector3(0.5, 0.5, 0.5)  # Make it smaller
```

### Orientation
If your model faces the wrong direction:
```gdscript
model_instance.rotation_degrees = Vector3(0, 90, 0)  # Rotate 90 degrees
```

### Animations
If your model has animations:
```gdscript
var animation_player = model_instance.get_node("AnimationPlayer")
if animation_player:
	animation_player.play("walk")  # Play walk animation
```

## Common Issues and Solutions

### Model appears black/no texture
- Check that textures are in the same folder as the model
- Re-import the model: Right-click → Reimport

### Model is invisible
- Check the scale (might be too small)
- Verify it's added as a child: `add_child(model_instance)`
- Check that layers/culling settings are correct

### Model appears at wrong height
- Adjust the Y position based on terrain height
- Use `get_height_at_world_pos()` to snap to terrain

### Import fails
- Ensure the file format is supported
- Try converting to .glb format
- Check Godot console for error messages

## Example: Quick Character Replacement

1. Download a character from Quaternius (free, CC0)
2. Place `character.glb` in `assets/models/`
3. Edit `scripts/player.gd`:

```gdscript
func _create_robot_body():
	var character = load("res://assets/models/character.glb").instantiate()
	character.scale = Vector3(0.8, 0.8, 0.8)
	add_child(character)
	robot_parts.append(character)
```

4. Press F5 to run - your new character appears!

## Resources

- [Godot 3D Asset Pipeline](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/index.html)
- [glTF in Godot](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/gltf.html)
- [Best Practices for 3D](https://docs.godotengine.org/en/stable/tutorials/3d/3d_rendering_limitations.html)
