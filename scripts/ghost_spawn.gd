extends Node3D

@export var ghost_scene: PackedScene
@export var spawn_markers: Array[Marker3D] = []
@export var patrol_markers: Array[Marker3D] = []

var ghost_instance: Node3D = null

func _ready():
	# Wait a frame for scene to fully load
	await get_tree().process_frame
	spawn_ghost_randomly()

func spawn_ghost_randomly():
	if spawn_markers.size() == 0:
		push_error("No spawn markers set for ghost!")
		return
	
	if not ghost_scene:
		push_error("Ghost scene not assigned!")
		return
	
	# Pick random spawn point
	var random_index = randi() % spawn_markers.size()
	var spawn_point = spawn_markers[random_index]
	
	# Instance ghost
	ghost_instance = ghost_scene.instantiate()
	add_child(ghost_instance)
	
	# Set position
	ghost_instance.global_position = spawn_point.global_position
	
	# CRITICAL: Assign patrol markers
	if "patrol_markers" in ghost_instance:
		ghost_instance.patrol_markers = patrol_markers
		print("Ghost spawned at: ", spawn_point.name)
		print("Ghost assigned ", patrol_markers.size(), " patrol points")
		
		# Force ghost to convert markers to positions
		if ghost_instance.has_method("convert_markers_to_positions"):
			ghost_instance.convert_markers_to_positions()
			print("Ghost patrol points converted: ", ghost_instance.patrol_points.size())
	else:
		push_error("Ghost doesn't have patrol_markers property!")

func get_ghost() -> Node3D:
	return ghost_instance
