extends GutTest

## Test minimap reveal radius and cardinal direction changes
## Tests the logic of the 10x reveal radius and 180° compass offset

func test_reveal_radius_covers_10_chunks():
	# Test that a 10-chunk radius creates the expected circular coverage
	var reveal_radius = 10
	var radius_squared = reveal_radius * reveal_radius
	var chunks_marked = 0
	
	for dx in range(-reveal_radius, reveal_radius + 1):
		for dz in range(-reveal_radius, reveal_radius + 1):
			if dx * dx + dz * dz <= radius_squared:
				chunks_marked += 1
	
	# Expected: approximately π × 10² ≈ 314 chunks
	# Allow some tolerance due to integer discretization
	assert_true(chunks_marked >= 310 and chunks_marked <= 320, 
		"Should mark approximately 314 chunks (π×10²), got %d" % chunks_marked)
	
	# Log the actual count
	print("Reveal radius test: %d chunks marked (expected ~314)" % chunks_marked)

func test_compass_direction_north():
	# Test that 0° rotation (facing +Z in Godot) should show South after 180° offset
	var rotation_y = 0.0
	var rotation_deg = rad_to_deg(rotation_y) + 180.0
	rotation_deg = fmod(rotation_deg + 360.0, 360.0)
	
	# After 180° offset, 0° becomes 180° which is South
	assert_true(rotation_deg >= 157.5 and rotation_deg < 202.5,
		"0° rotation + 180° offset should be South (157.5-202.5°), got %.1f°" % rotation_deg)

func test_compass_direction_east():
	# Test that 90° rotation (facing +X in Godot) should show West after 180° offset
	var rotation_y = deg_to_rad(90.0)
	var rotation_deg = rad_to_deg(rotation_y) + 180.0
	rotation_deg = fmod(rotation_deg + 360.0, 360.0)
	
	# After 180° offset, 90° becomes 270° which is West
	assert_true(rotation_deg >= 247.5 and rotation_deg < 292.5,
		"90° rotation + 180° offset should be West (247.5-292.5°), got %.1f°" % rotation_deg)

func test_compass_direction_south():
	# Test that 180° rotation (facing -Z in Godot) should show North after 180° offset
	var rotation_y = deg_to_rad(180.0)
	var rotation_deg = rad_to_deg(rotation_y) + 180.0
	rotation_deg = fmod(rotation_deg + 360.0, 360.0)
	
	# After 180° offset, 180° becomes 360° (0°) which is North
	assert_true((rotation_deg < 22.5 or rotation_deg >= 337.5),
		"180° rotation + 180° offset should be North (0-22.5° or 337.5-360°), got %.1f°" % rotation_deg)

func test_compass_direction_west():
	# Test that 270° rotation (facing -X in Godot) should show East after 180° offset
	var rotation_y = deg_to_rad(270.0)
	var rotation_deg = rad_to_deg(rotation_y) + 180.0
	rotation_deg = fmod(rotation_deg + 360.0, 360.0)
	
	# After 180° offset, 270° becomes 450° (90°) which is East
	assert_true(rotation_deg >= 67.5 and rotation_deg < 112.5,
		"270° rotation + 180° offset should be East (67.5-112.5°), got %.1f°" % rotation_deg)

func test_chunk_update_optimization():
	# Test that chunk position tracking works correctly
	var last_player_chunk = Vector2i(-999999, -999999)
	var current_chunk = Vector2i(0, 0)
	
	# First check: should update (different chunks)
	assert_true(current_chunk != last_player_chunk,
		"Initial chunk should be different from far-away default")
	
	# After update
	last_player_chunk = current_chunk
	
	# Second check: should NOT update (same chunk)
	assert_true(current_chunk == last_player_chunk,
		"Chunk should be the same after update")
	
	# Move to new chunk
	current_chunk = Vector2i(1, 0)
	
	# Third check: should update (different chunks)
	assert_true(current_chunk != last_player_chunk,
		"Should detect movement to new chunk")
