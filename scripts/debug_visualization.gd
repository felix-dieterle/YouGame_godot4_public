extends Node3D
class_name DebugVisualization

# Preload dependencies
const ClusterSystem = preload("res://scripts/cluster_system.gd")

var show_chunk_borders: bool = true
var show_walkability: bool = false
var world_manager: WorldManager

func _ready():
    world_manager = get_tree().get_first_node_in_group("WorldManager")

func draw_chunk_borders(chunk: Chunk):
    if not show_chunk_borders:
        return
    
    var immediate_mesh = ImmediateMesh.new()
    var material = StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.albedo_color = Color.YELLOW
    
    immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
    
    var size = Chunk.CHUNK_SIZE
    
    # Draw border lines
    immediate_mesh.surface_add_vertex(Vector3(0, 0, 0))
    immediate_mesh.surface_add_vertex(Vector3(size, 0, 0))
    
    immediate_mesh.surface_add_vertex(Vector3(size, 0, 0))
    immediate_mesh.surface_add_vertex(Vector3(size, 0, size))
    
    immediate_mesh.surface_add_vertex(Vector3(size, 0, size))
    immediate_mesh.surface_add_vertex(Vector3(0, 0, size))
    
    immediate_mesh.surface_add_vertex(Vector3(0, 0, size))
    immediate_mesh.surface_add_vertex(Vector3(0, 0, 0))
    
    immediate_mesh.surface_end()
    
    var mesh_instance = MeshInstance3D.new()
    mesh_instance.mesh = immediate_mesh
    mesh_instance.position = chunk.position
    chunk.add_child(mesh_instance)

func toggle_chunk_borders():
    show_chunk_borders = not show_chunk_borders

func toggle_walkability():
    show_walkability = not show_walkability
    # Walkability is already visualized in chunk mesh colors

var show_clusters: bool = false

func toggle_clusters():
    show_clusters = not show_clusters
    _redraw_cluster_visualization()

func _redraw_cluster_visualization():
    # Remove existing cluster visualizations
    for child in get_children():
        if child.name.begins_with("ClusterViz_"):
            child.queue_free()
    
    if not show_clusters:
        return
    
    # Draw all active clusters
    for cluster_key in ClusterSystem.all_clusters:
        var cluster = ClusterSystem.all_clusters[cluster_key]
        _draw_cluster(cluster)

func _draw_cluster(cluster):
    # Calculate world position of cluster center
    var world_pos = Vector3(
        cluster.center_chunk.x * ClusterSystem.CHUNK_SIZE + cluster.center_pos.x,
        0,
        cluster.center_chunk.y * ClusterSystem.CHUNK_SIZE + cluster.center_pos.y
    )
    
    # Create a circle to show cluster boundary
    var immediate_mesh = ImmediateMesh.new()
    var material = StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    
    # Different colors for different cluster types
    if cluster.type == ClusterSystem.ClusterType.FOREST:
        material.albedo_color = Color(0.2, 0.8, 0.2, 0.5)  # Green for forests
    else:
        material.albedo_color = Color(0.8, 0.6, 0.2, 0.5)  # Orange for settlements
    
    immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, material)
    
    var segments = 32
    for i in range(segments + 1):
        var angle = (i / float(segments)) * TAU
        var x = cos(angle) * cluster.radius
        var z = sin(angle) * cluster.radius
        immediate_mesh.surface_add_vertex(Vector3(x, 2.0, z))  # Elevated for visibility
    
    immediate_mesh.surface_end()
    
    var mesh_instance = MeshInstance3D.new()
    mesh_instance.mesh = immediate_mesh
    mesh_instance.position = world_pos
    mesh_instance.name = "ClusterViz_%d" % cluster.cluster_id
    add_child(mesh_instance)
