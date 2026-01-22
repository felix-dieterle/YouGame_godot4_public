extends Node
class_name TorchSystem

## Torch System - Handles torch creation and management
##
## Provides utility functions for creating torch nodes with proper lighting

## Create a torch node with light
## Parameters:
## - light_energy: Brightness of the torch light (default: 5.0)
## - light_range: How far the torch light reaches in meters (default: 30.0)
## - light_attenuation: Light falloff rate (default: 0.5)
static func create_torch_node(light_energy: float = 5.0, light_range: float = 30.0, light_attenuation: float = 0.5) -> Node3D:
    var torch = Node3D.new()
    torch.name = "Torch"
    torch.add_to_group("Torches")  # Add to group for save/load
    
    # Create visual torch (simple stick with flame)
    var stick = MeshInstance3D.new()
    var stick_mesh = CylinderMesh.new()
    stick_mesh.height = 1.0
    stick_mesh.top_radius = 0.05
    stick_mesh.bottom_radius = 0.05
    stick.mesh = stick_mesh
    stick.position = Vector3(0, 0.5, 0)
    
    var stick_material = StandardMaterial3D.new()
    stick_material.albedo_color = Color(0.3, 0.2, 0.1)  # Brown wood
    stick.set_surface_override_material(0, stick_material)
    torch.add_child(stick)
    
    # Create flame (glowing sphere)
    var flame = MeshInstance3D.new()
    var flame_mesh = SphereMesh.new()
    flame_mesh.radius = 0.2
    flame_mesh.height = 0.4
    flame.mesh = flame_mesh
    flame.position = Vector3(0, 1.2, 0)
    
    var flame_material = StandardMaterial3D.new()
    flame_material.albedo_color = Color(1.0, 0.6, 0.1)  # Orange flame
    flame_material.emission_enabled = true
    flame_material.emission = Color(1.0, 0.5, 0.0)
    flame_material.emission_energy_multiplier = 3.0
    flame.set_surface_override_material(0, flame_material)
    torch.add_child(flame)
    
    # Create bright omni light
    var light = OmniLight3D.new()
    light.light_color = Color(1.0, 0.7, 0.3)  # Warm orange light
    light.light_energy = light_energy
    light.omni_range = light_range
    light.omni_attenuation = light_attenuation
    light.shadow_enabled = true
    light.position = Vector3(0, 1.2, 0)
    torch.add_child(light)
    
    return torch
