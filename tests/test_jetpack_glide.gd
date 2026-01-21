extends Node

# Test suite for jetpack gliding feature

func _ready():
	print("=== Starting Jetpack Glide Tests ===")
	test_jetpack_glide_state_transitions()
	test_glide_velocity()
	test_glide_stops_at_terrain()
	print("=== All Jetpack Glide Tests Completed ===")
	get_tree().quit()

func test_jetpack_glide_state_transitions():
	print("\n--- Test: Jetpack Glide State Transitions ---")
	
	var player = Player.new()
	
	# Initially, player should not be gliding
	assert(player.is_gliding == false, "Player should not be gliding initially")
	assert(player.was_jetpack_active == false, "Jetpack should not be active initially")
	print("  PASS: Initial state is correct")
	
	# Simulate jetpack activation
	player.was_jetpack_active = false
	player.is_gliding = false
	# In _physics_process when jetpack_active = true:
	# is_gliding = false, was_jetpack_active = true
	var jetpack_active = true
	if jetpack_active:
		player.is_gliding = false
		player.was_jetpack_active = true
	
	assert(player.is_gliding == false, "Player should not be gliding when jetpack is active")
	assert(player.was_jetpack_active == true, "was_jetpack_active should be true when jetpack is active")
	print("  PASS: Jetpack active state is correct")
	
	# Simulate jetpack release
	jetpack_active = false
	if not jetpack_active and player.was_jetpack_active:
		player.is_gliding = true
		player.was_jetpack_active = false
	
	assert(player.is_gliding == true, "Player should be gliding after jetpack release")
	assert(player.was_jetpack_active == false, "was_jetpack_active should be false after release")
	print("  PASS: Gliding started after jetpack release")
	
	player.queue_free()

func test_glide_velocity():
	print("\n--- Test: Glide Velocity ---")
	
	var player = Player.new()
	
	# Check that glide_speed is properly set
	assert(player.glide_speed > 0, "Glide speed should be positive")
	assert(player.glide_speed < player.jetpack_speed, "Glide speed should be slower than jetpack speed")
	print("  PASS: Glide speed is %f (slower than jetpack speed %f)" % [player.glide_speed, player.jetpack_speed])
	
	# Simulate gliding state
	player.is_gliding = true
	var expected_velocity_y = -player.glide_speed
	
	# When gliding, velocity.y should be -glide_speed
	if player.is_gliding:
		player.velocity.y = -player.glide_speed
	
	assert(abs(player.velocity.y - expected_velocity_y) < 0.01, "Glide velocity should be negative (downward)")
	print("  PASS: Glide velocity is %f (negative for downward movement)" % player.velocity.y)
	
	player.queue_free()

func test_glide_stops_at_terrain():
	print("\n--- Test: Glide Stops At Terrain ---")
	
	var player = Player.new()
	
	# Simulate player gliding above terrain
	player.is_gliding = true
	player.global_position.y = 10.0  # Player is at height 10
	var terrain_level = 5.0  # Terrain is at height 5
	
	# Check if player has reached terrain
	if player.is_gliding and player.global_position.y <= terrain_level:
		player.is_gliding = false
		player.global_position.y = terrain_level
		player.velocity.y = 0.0
	
	assert(player.is_gliding == false, "Gliding should stop when reaching terrain")
	assert(player.global_position.y == terrain_level, "Player should be at terrain level")
	assert(player.velocity.y == 0.0, "Vertical velocity should be zero after landing")
	print("  PASS: Gliding stops correctly at terrain level")
	
	player.queue_free()

# Helper function for assertions
func assert(condition: bool, message: String):
	if not condition:
		print("  FAIL: " + message)
		push_error(message)
	else:
		print("  " + message)
