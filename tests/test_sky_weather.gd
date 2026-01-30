extends Node

# Test suite for sky weather integration
const WeatherSystem = preload("res://scripts/systems/environment/weather_system.gd")

var test_failed = false

func _ready():
	print("=== Starting Sky Weather Tests ===")
	test_weather_params_structure()
	test_sky_parameter_ranges()
	test_weather_state_consistency()
	print("=== All Sky Weather Tests Completed ===")
	
	if test_failed:
		print("OVERALL: FAILED")
		get_tree().quit(1)
	else:
		print("OVERALL: PASSED")
		get_tree().quit(0)

func test_weather_params_structure():
	print("\n--- Test: Weather Parameters Structure ---")
	
	var weather_system = WeatherSystem.new()
	var all_valid = true
	
	# Test all weather states
	var weather_states = [
		WeatherSystem.WeatherState.CLEAR,
		WeatherSystem.WeatherState.LIGHT_FOG,
		WeatherSystem.WeatherState.HEAVY_FOG,
		WeatherSystem.WeatherState.LIGHT_RAIN,
		WeatherSystem.WeatherState.HEAVY_RAIN
	]
	
	var required_params = ["fog_density", "rain_intensity", "turbidity", "mie_coefficient", "rayleigh_coefficient"]
	
	for state in weather_states:
		var params = weather_system._get_weather_params(state)
		
		# Check all required parameters exist
		for param_name in required_params:
			if not params.has(param_name):
				print("FAIL: Weather state %d missing parameter: %s" % [state, param_name])
				all_valid = false
		
		# Verify all parameters are numbers
		for param_name in params.keys():
			if typeof(params[param_name]) != TYPE_FLOAT and typeof(params[param_name]) != TYPE_INT:
				print("FAIL: Parameter %s in state %d is not a number" % [param_name, state])
				all_valid = false
	
	if all_valid:
		print("PASS: All weather states have required parameters with correct types")
	else:
		test_failed = true
	
	weather_system.free()

func test_sky_parameter_ranges():
	print("\n--- Test: Sky Parameter Ranges ---")
	
	var weather_system = WeatherSystem.new()
	var all_valid = true
	
	var weather_states = [
		{"name": "CLEAR", "state": WeatherSystem.WeatherState.CLEAR},
		{"name": "LIGHT_FOG", "state": WeatherSystem.WeatherState.LIGHT_FOG},
		{"name": "HEAVY_FOG", "state": WeatherSystem.WeatherState.HEAVY_FOG},
		{"name": "LIGHT_RAIN", "state": WeatherSystem.WeatherState.LIGHT_RAIN},
		{"name": "HEAVY_RAIN", "state": WeatherSystem.WeatherState.HEAVY_RAIN}
	]
	
	for state_info in weather_states:
		var params = weather_system._get_weather_params(state_info.state)
		var state_name = state_info.name
		
		# Check turbidity range (should be 0-100, we use 10-30)
		if params.turbidity < 0 or params.turbidity > 100:
			print("FAIL: %s turbidity out of range: %.2f (expected 0-100)" % [state_name, params.turbidity])
			all_valid = false
		
		# Check mie_coefficient range (should be 0-1)
		if params.mie_coefficient < 0 or params.mie_coefficient > 1:
			print("FAIL: %s mie_coefficient out of range: %.3f (expected 0-1)" % [state_name, params.mie_coefficient])
			all_valid = false
		
		# Check rayleigh_coefficient range (should be positive)
		if params.rayleigh_coefficient < 0:
			print("FAIL: %s rayleigh_coefficient is negative: %.2f" % [state_name, params.rayleigh_coefficient])
			all_valid = false
		
		print("  %s: turbidity=%.1f, mie=%.3f, rayleigh=%.1f" % [
			state_name, 
			params.turbidity, 
			params.mie_coefficient, 
			params.rayleigh_coefficient
		])
	
	if all_valid:
		print("PASS: All sky parameters are within valid ranges")
	else:
		test_failed = true
	
	weather_system.free()

func test_weather_state_consistency():
	print("\n--- Test: Weather State Consistency ---")
	
	var weather_system = WeatherSystem.new()
	var all_valid = true
	
	# Test that weather progression shows logical changes
	var clear_params = weather_system._get_weather_params(WeatherSystem.WeatherState.CLEAR)
	var light_rain_params = weather_system._get_weather_params(WeatherSystem.WeatherState.LIGHT_RAIN)
	var heavy_rain_params = weather_system._get_weather_params(WeatherSystem.WeatherState.HEAVY_RAIN)
	
	# Sky should get darker (lower rayleigh) as weather worsens
	if clear_params.rayleigh_coefficient <= light_rain_params.rayleigh_coefficient:
		print("FAIL: CLEAR rayleigh should be higher than LIGHT_RAIN")
		all_valid = false
	
	if light_rain_params.rayleigh_coefficient <= heavy_rain_params.rayleigh_coefficient:
		print("FAIL: LIGHT_RAIN rayleigh should be higher than HEAVY_RAIN")
		all_valid = false
	
	# Turbidity should increase as weather worsens (more clouds)
	if clear_params.turbidity >= light_rain_params.turbidity:
		print("FAIL: CLEAR turbidity should be lower than LIGHT_RAIN")
		all_valid = false
	
	if light_rain_params.turbidity >= heavy_rain_params.turbidity:
		print("FAIL: LIGHT_RAIN turbidity should be lower than HEAVY_RAIN")
		all_valid = false
	
	# Mie coefficient should increase as weather worsens (more haze)
	if clear_params.mie_coefficient >= light_rain_params.mie_coefficient:
		print("FAIL: CLEAR mie should be lower than LIGHT_RAIN")
		all_valid = false
	
	if light_rain_params.mie_coefficient >= heavy_rain_params.mie_coefficient:
		print("FAIL: LIGHT_RAIN mie should be lower than HEAVY_RAIN")
		all_valid = false
	
	if all_valid:
		print("PASS: Weather state progression is logically consistent")
		print("  Sky darkens as weather worsens (rayleigh decreases)")
		print("  Clouds increase as weather worsens (turbidity increases)")
		print("  Haze increases as weather worsens (mie increases)")
	else:
		test_failed = true
	
	weather_system.free()
