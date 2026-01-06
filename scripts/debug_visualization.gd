extends Node3D
class_name DebugVisualization

var show_chunk_borders: bool = true
var show_walkability: bool = false
var world_manager: WorldManager

func _ready():
	world_manager = get_tree().get_first_node_in_group("WorldManager")

func _process(_delta):
	queue_redraw()

func _draw():
	pass  # 3D drawing done in _process with ImmediateMesh

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
