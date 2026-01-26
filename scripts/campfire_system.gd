extends Node
class_name CampfireSystem

## Campfire System - Handles campfire creation and management
##
## Provides utility functions for creating campfire nodes with proper lighting and fire effects

## Create a campfire node with light
## Parameters:
## - light_energy: Brightness of the campfire light (default: 8.0)
## - light_range: How far the campfire light reaches in meters (default: 40.0)
## - light_attenuation: Light falloff rate (default: 0.8)
static func create_campfire_node(light_energy: float = 8.0, light_range: float = 40.0, light_attenuation: float = 0.8) -> Node3D:
    var campfire = Node3D.new()
    campfire.name = "Campfire"
    campfire.add_to_group("Campfires")  # Add to group for save/load
    
    # Create stone base (multiple stones arranged in a circle)
    for i in range(6):
        var stone = MeshInstance3D.new()
        var stone_mesh = BoxMesh.new()
        stone_mesh.size = Vector3(0.3, 0.2, 0.4)
        stone.mesh = stone_mesh
        
        var angle = i * (2.0 * PI / 6.0)
        var radius = 0.6
        stone.position = Vector3(cos(angle) * radius, 0.1, sin(angle) * radius)
        stone.rotation.y = angle + PI / 2.0
        
        var stone_material = StandardMaterial3D.new()
        stone_material.albedo_texture = load("res://assets/textures/stone.png")
        stone_material.albedo_color = Color(0.4, 0.4, 0.45)  # Gray stone tint
        stone_material.roughness = 0.9
        stone_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
        stone.set_surface_override_material(0, stone_material)
        campfire.add_child(stone)
    
    # Create wood logs in center
    for i in range(3):
        var log = MeshInstance3D.new()
        var log_mesh = CylinderMesh.new()
        log_mesh.height = 0.8
        log_mesh.top_radius = 0.08
        log_mesh.bottom_radius = 0.08
        log.mesh = log_mesh
        
        var angle = i * (2.0 * PI / 3.0)
        log.position = Vector3(cos(angle) * 0.15, 0.25, sin(angle) * 0.15)
        log.rotation.z = PI / 2.0
        log.rotation.y = angle
        
        var log_material = StandardMaterial3D.new()
        log_material.albedo_texture = load("res://assets/textures/wood.png")
        log_material.albedo_color = Color(0.3, 0.2, 0.1)  # Brown wood tint
        log_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
        log.set_surface_override_material(0, log_material)
        campfire.add_child(log)
    
    # Create main fire (glowing sphere - larger than torch)
    var fire = MeshInstance3D.new()
    var fire_mesh = SphereMesh.new()
    fire_mesh.radius = 0.35
    fire_mesh.height = 0.7
    fire.mesh = fire_mesh
    fire.position = Vector3(0, 0.5, 0)
    
    var fire_material = StandardMaterial3D.new()
    fire_material.albedo_color = Color(1.0, 0.5, 0.1)  # Orange fire
    fire_material.emission_enabled = true
    fire_material.emission = Color(1.0, 0.4, 0.0)
    fire_material.emission_energy_multiplier = 4.0
    fire.set_surface_override_material(0, fire_material)
    campfire.add_child(fire)
    
    # Create brighter omni light (brighter and reaches further than torch)
    var light = OmniLight3D.new()
    light.light_color = Color(1.0, 0.6, 0.2)  # Warm orange light
    light.light_energy = light_energy
    light.omni_range = light_range
    light.omni_attenuation = light_attenuation
    light.shadow_enabled = true
    light.position = Vector3(0, 0.5, 0)
    campfire.add_child(light)
    
    # Add campfire crackling sound
    var audio_player = AudioStreamPlayer3D.new()
    audio_player.stream = load("res://assets/sounds/campfire_crackle.wav")
    audio_player.volume_db = -5.0  # Slightly quieter
    audio_player.max_distance = 20.0  # Can hear from 20 meters away
    campfire.add_child(audio_player)
    # Start playing after added to scene tree for better control
    audio_player.play()
    
    return campfire
