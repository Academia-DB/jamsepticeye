# debug_draw_3d.gd
extends Node

var immediate_mesh: ImmediateMesh
var material: StandardMaterial3D
var mesh_instance: MeshInstance3D

func _ready():
	# Create mesh instance for debug drawing
	immediate_mesh = ImmediateMesh.new()
	material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = immediate_mesh
	mesh_instance.material_override = material
	
	# Add to root
	get_tree().root.call_deferred("add_child", mesh_instance)

var lines = []

func draw_line(start: Vector3, end: Vector3, color: Color, duration: float):
	lines.append({
		"start": start,
		"end": end, 
		"color": color,
		"time": duration
	})

func _process(delta):
	immediate_mesh.clear_surfaces()
	
	# Remove expired lines
	for i in range(lines.size() - 1, -1, -1):
		lines[i].time -= delta
		if lines[i].time <= 0:
			lines.remove_at(i)
	
	# Draw active lines
	if lines.size() > 0:
		immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		
		for line in lines:
			immediate_mesh.surface_set_color(line.color)
			immediate_mesh.surface_add_vertex(line.start)
			immediate_mesh.surface_add_vertex(line.end)
		
		immediate_mesh.surface_end()
