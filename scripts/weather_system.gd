extends Node3D
class_name WeatherSystem

# Weather states
enum WeatherState {
    CLEAR,
    LIGHT_FOG,
    HEAVY_FOG,
    LIGHT_RAIN,
    HEAVY_RAIN
}

# Current and target weather
var current_weather: WeatherState = WeatherState.CLEAR
var target_weather: WeatherState = WeatherState.CLEAR
var transition_progress: float = 1.0  # 0.0 = current, 1.0 = target

# Weather change timing
@export var min_weather_duration: float = 120.0  # 2 minutes minimum
@export var max_weather_duration: float = 300.0  # 5 minutes maximum
@export var transition_duration: float = 30.0    # 30 seconds to transition
var time_in_current_weather: float = 0.0
var next_weather_change: float = 0.0

# Visual elements
var fog_environment: Environment
var rain_particles: GPUParticles3D
var world_environment: WorldEnvironment

# Player reference for positioning rain
var player: Node3D

func _ready():
    # Find player
    player = get_tree().get_first_node_in_group("Player")
    if not player:
        player = get_parent().get_node_or_null("Player")
    
    # Setup world environment
    _setup_environment()
    
    # Setup rain particles
    _setup_rain_particles()
    
    # Set initial weather change time
    next_weather_change = randf_range(min_weather_duration, max_weather_duration)

func _process(delta):
    time_in_current_weather += delta
    
    # Check if it's time to change weather
    if time_in_current_weather >= next_weather_change and transition_progress >= 1.0:
        _start_weather_transition()
    
    # Update transition
    if transition_progress < 1.0:
        transition_progress += delta / transition_duration
        transition_progress = min(transition_progress, 1.0)
        _apply_weather_transition()
        
        # When transition completes, update current weather
        if transition_progress >= 1.0:
            current_weather = target_weather
    
    # Update rain position to follow player
    if rain_particles and player:
        rain_particles.global_position = player.global_position + Vector3(0, 10, 0)

func _setup_environment():
    # Find existing WorldEnvironment in the scene tree
    world_environment = get_tree().get_first_node_in_group("WorldEnvironment")
    
    if not world_environment:
        # Check parent's WorldEnvironment
        world_environment = get_parent().get_node_or_null("WorldEnvironment")
    
    if world_environment and world_environment.environment:
        fog_environment = world_environment.environment
    else:
        push_warning("WeatherSystem: Could not find WorldEnvironment, weather effects may not work")
        return
    
    # Ensure fog is disabled initially
    fog_environment.fog_enabled = false
    fog_environment.volumetric_fog_enabled = false

func _setup_rain_particles():
    # Create rain particle system
    rain_particles = GPUParticles3D.new()
    rain_particles.emitting = false
    rain_particles.amount = 1000
    rain_particles.lifetime = 2.0
    rain_particles.visibility_aabb = AABB(Vector3(-20, -5, -20), Vector3(40, 15, 40))
    
    # Create particle process material
    var particle_material = ParticleProcessMaterial.new()
    particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    particle_material.emission_box_extents = Vector3(15, 0.1, 15)
    particle_material.direction = Vector3(0, -1, 0)
    particle_material.gravity = Vector3(0, -15, 0)
    particle_material.initial_velocity_min = 5.0
    particle_material.initial_velocity_max = 8.0
    particle_material.scale_min = 0.05
    particle_material.scale_max = 0.1
    rain_particles.process_material = particle_material
    
    # Create simple quad mesh for raindrops
    var quad_mesh = QuadMesh.new()
    quad_mesh.size = Vector2(0.1, 0.5)
    rain_particles.draw_pass_1 = quad_mesh
    
    # Create material for raindrops
    var rain_material = StandardMaterial3D.new()
    rain_material.albedo_color = Color(0.7, 0.7, 0.9, 0.3)
    rain_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    rain_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    rain_particles.draw_pass_1.surface_set_material(0, rain_material)
    
    add_child(rain_particles)

func _start_weather_transition():
    # Choose a new random weather state
    var weather_weights = {
        WeatherState.CLEAR: 40,
        WeatherState.LIGHT_FOG: 25,
        WeatherState.HEAVY_FOG: 10,
        WeatherState.LIGHT_RAIN: 20,
        WeatherState.HEAVY_RAIN: 5
    }
    
    # Pick weighted random weather
    var total_weight = 0
    for weight in weather_weights.values():
        total_weight += weight
    
    var random_value = randf() * total_weight
    var accumulated_weight = 0
    
    for state in weather_weights.keys():
        accumulated_weight += weather_weights[state]
        if random_value <= accumulated_weight:
            target_weather = state
            break
    
    # Don't transition to the same weather
    if target_weather == current_weather:
        # Try next weather state (cycle through 5 states: CLEAR, LIGHT_FOG, HEAVY_FOG, LIGHT_RAIN, HEAVY_RAIN)
        target_weather = (current_weather + 1) % 5
    
    # Start transition
    transition_progress = 0.0
    time_in_current_weather = 0.0
    next_weather_change = randf_range(min_weather_duration, max_weather_duration)

func _apply_weather_transition():
    # Get weather parameters for current and target
    var current_params = _get_weather_params(current_weather)
    var target_params = _get_weather_params(target_weather)
    
    # Interpolate fog density
    var fog_density = lerp(current_params.fog_density, target_params.fog_density, transition_progress)
    
    if fog_density > 0.0:
        fog_environment.fog_enabled = true
        fog_environment.fog_density = fog_density
        fog_environment.fog_light_color = Color(0.8, 0.8, 0.85)
        fog_environment.fog_sky_affect = 0.5
    else:
        fog_environment.fog_enabled = false
    
    # Interpolate rain intensity
    var rain_intensity = lerp(current_params.rain_intensity, target_params.rain_intensity, transition_progress)
    
    if rain_particles:
        if rain_intensity > 0.0:
            rain_particles.emitting = true
            rain_particles.amount = int(1000 * rain_intensity)
        else:
            rain_particles.emitting = false

func _get_weather_params(weather: WeatherState) -> Dictionary:
    match weather:
        WeatherState.CLEAR:
            return {
                "fog_density": 0.0,
                "rain_intensity": 0.0
            }
        WeatherState.LIGHT_FOG:
            return {
                "fog_density": 0.001,
                "rain_intensity": 0.0
            }
        WeatherState.HEAVY_FOG:
            return {
                "fog_density": 0.005,
                "rain_intensity": 0.0
            }
        WeatherState.LIGHT_RAIN:
            return {
                "fog_density": 0.0005,
                "rain_intensity": 0.3
            }
        WeatherState.HEAVY_RAIN:
            return {
                "fog_density": 0.002,
                "rain_intensity": 1.0
            }
    
    # Default (shouldn't reach here)
    return {
        "fog_density": 0.0,
        "rain_intensity": 0.0
    }
