extends Camera3D

# Target to follow
@export var target: Node3D

# Camera positioning
@export var offset: Vector3 = Vector3(6, 6, 6)  # Adjust for your isometric angle
@export var look_at_offset: Vector3 = Vector3(0, 0, 0)  # Offset from target position to look at

# Camera behavior
@export var follow_smoothing: float = 5.0
@export var rotation_smoothing: float = 3.0

# Cutscene control
var is_in_cutscene: bool = false
var cutscene_target_position: Vector3
var cutscene_target_rotation: Vector3
var cutscene_transition_speed: float = 2.0

func _ready():
	if target:
		# Initialize camera position
		global_position = target.global_position + offset
		look_at(target.global_position + look_at_offset)

func _process(delta):
	if is_in_cutscene:
		handle_cutscene_movement(delta)
	elif target:
		handle_follow_movement(delta)

func handle_follow_movement(delta):
	# Smoothly follow the target
	var target_pos = target.global_position + offset
	global_position = global_position.lerp(target_pos, follow_smoothing * delta)
	
	# Look at the target
	var look_target = target.global_position + look_at_offset
	var current_transform = global_transform
	current_transform = current_transform.looking_at(look_target, Vector3.UP)
	global_transform = global_transform.interpolate_with(current_transform, rotation_smoothing * delta)

func handle_cutscene_movement(delta):
	# Move to cutscene position and rotation
	global_position = global_position.lerp(cutscene_target_position, cutscene_transition_speed * delta)
	
	# Smoothly rotate to target rotation
	rotation.x = lerp_angle(rotation.x, cutscene_target_rotation.x, cutscene_transition_speed * delta)
	rotation.y = lerp_angle(rotation.y, cutscene_target_rotation.y, cutscene_transition_speed * delta)
	rotation.z = lerp_angle(rotation.z, cutscene_target_rotation.z, cutscene_transition_speed * delta)

# Cutscene functions
func start_cutscene(target_pos: Vector3, target_rot: Vector3, transition_speed: float = 2.0):
	"""Move camera to a specific position and rotation for cutscene"""
	is_in_cutscene = true
	cutscene_target_position = target_pos
	cutscene_target_rotation = target_rot
	cutscene_transition_speed = transition_speed

func start_cutscene_look_at(target_pos: Vector3, look_at_pos: Vector3, transition_speed: float = 2.0):
	"""Move camera to position and look at a specific point"""
	is_in_cutscene = true
	cutscene_target_position = target_pos
	cutscene_transition_speed = transition_speed
	
	# Calculate rotation needed to look at the target
	var temp_transform = Transform3D()
	temp_transform.origin = target_pos
	temp_transform = temp_transform.looking_at(look_at_pos, Vector3.UP)
	cutscene_target_rotation = temp_transform.basis.get_euler()

func end_cutscene():
	"""Return camera to following the player"""
	is_in_cutscene = false

func set_offset(new_offset: Vector3, smooth: bool = true):
	"""Change camera offset (useful for different camera angles in different areas)"""
	if smooth:
		var tween = create_tween()
		tween.tween_property(self, "offset", new_offset, 1.0)
	else:
		offset = new_offset

# Quick cutscene helper - focus on a specific node
func focus_on_node(node: Node3D, distance: float = 10.0, duration: float = 1.0):
	"""Quick cutscene: focus camera on a specific node"""
	var direction = (global_position - node.global_position).normalized()
	var new_position = node.global_position + direction * distance
	start_cutscene_look_at(new_position, node.global_position, duration)
