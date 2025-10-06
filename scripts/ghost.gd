extends CharacterBody3D
# Ghost enemy that patrols, detects player, chases, and returns to patrol

# Patrol settings
@export var patrol_markers: Array[Marker3D] = []  # Drag Marker3D nodes here
var patrol_points: Array[Vector3] = []  # Converted from markers
@export var patrol_speed: float = 2.0
@export var wait_time_at_point: float = 2.0
@export var can_enter_bathrooms: bool = false
@export var can_enter_exit: bool = false

# Navigation regions (optional - for smarter pathing)
@export var restricted_rooms: Array[String] = ["Bathroom1", "Bathroom2", "Exit"]

# Chase settings
@export var detection_range: float = 15.0
@export var chase_speed: float = 4.0
@export var chase_duration: float = 10.0  # How long to chase before giving up
@export var search_duration: float = 4.0  # How long to search after losing player

# Speed increase per key (ghost gets faster)
@export var speed_increase_per_key: float = 0.5

# State machine
enum State { PATROL, CHASE, SEARCH, RETURN }
var current_state = State.PATROL

# Patrol state
var current_patrol_index: int = 0
var waiting: bool = false
var wait_timer: float = 0.0

# Chase state
var target_player: Node3D = null
var chase_timer: float = 0.0
var search_timer: float = 0.0
var last_known_player_position: Vector3

# Stuck detection
var stuck_timer: float = 0.0
var last_position: Vector3 = Vector3.ZERO
var stuck_threshold: float = 3.0  # seconds without meaningful movement

# References
var player: Node3D
@onready var detection_area: Area3D = $DetectionArea

func _ready():
	add_to_group("enemy")
	
	# Convert Marker3D nodes to Vector3 positions
	convert_markers_to_positions()
	
	# Find player
	player = get_tree().get_first_node_in_group("player")
	
	# Setup detection area signals
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_entered)
		detection_area.body_exited.connect(_on_detection_area_exited)
	
	# Validate patrol points
	if patrol_points.size() < 2:
		push_warning("Ghost needs at least 2 patrol points!")
	
	# Initialize last position
	last_position = global_position

func convert_markers_to_positions():
	"""Convert Marker3D references to Vector3 positions"""
	patrol_points.clear()
	for marker in patrol_markers:
		if marker:
			patrol_points.append(marker.global_position)
			print("Added patrol point: ", marker.global_position)
	
	if patrol_points.size() == 0:
		push_warning("No patrol markers assigned to ghost!")

func _physics_process(delta):
	# Update state machine
	match current_state:
		State.PATROL:
			handle_patrol(delta)
		State.CHASE:
			handle_chase(delta)
		State.SEARCH:
			handle_search(delta)
		State.RETURN:
			handle_return_to_patrol(delta)
	
	# Check if stuck
	check_if_stuck(delta)
	
	# Check for player in range (can detect during any state except return)
	if current_state != State.RETURN:
		check_player_detection()

func handle_patrol(delta):
	"""Patrol between waypoints"""
	if patrol_points.size() == 0:
		return
	
	# Handle waiting at waypoint
	if waiting:
		wait_timer -= delta
		if wait_timer <= 0:
			waiting = false
			next_patrol_point()
		return
	
	# Move toward current patrol point
	var target = patrol_points[current_patrol_index]
	move_toward_target(target, patrol_speed, delta)
	
	# Check if reached waypoint
	if global_position.distance_to(target) < 1.0:
		waiting = true
		wait_timer = wait_time_at_point

func handle_chase(delta):
	"""Chase the player"""
	if not player:
		current_state = State.SEARCH
		return
	
	# Update chase timer
	chase_timer += delta
	
	# Check if chase time expired
	if chase_timer >= chase_duration:
		print("Ghost: Chase timeout, entering search mode")
		enter_search_state()
		return
	
	# Check if player is still visible (line of sight)
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player > detection_range * 1.5:  # Lost player (too far)
		print("Ghost: Lost sight of player, searching...")
		enter_search_state()
		return
	
	# Check if wall is now blocking view
	if not has_line_of_sight_to_player():
		print("Ghost: Player hid behind wall, searching...")
		enter_search_state()
		return
	
	# Chase player with speed boost based on keys collected
	var current_chase_speed = chase_speed + (player.keys_collected * speed_increase_per_key)
	last_known_player_position = player.global_position
	move_toward_target(player.global_position, current_chase_speed, delta)

func handle_search(delta):
	"""Search at last known position"""
	search_timer += delta
	
	# Search duration expired
	if search_timer >= search_duration:
		print("Ghost: Search failed, returning to patrol")
		current_state = State.RETURN
		return
	
	# Move to last known position
	move_toward_target(last_known_player_position, patrol_speed, delta)
	
	# Check if player is detected again during search - BUT ONLY IF VISIBLE
	if player:
		var distance = global_position.distance_to(player.global_position)
		if distance <= detection_range and has_line_of_sight_to_player():
			print("Ghost: Found player during search!")
			enter_chase_state()

func handle_return_to_patrol(delta):
	"""Return to nearest patrol point"""
	if patrol_points.size() == 0:
		current_state = State.PATROL
		return
	
	# Find nearest patrol point
	var nearest_point = patrol_points[0]
	var nearest_distance = global_position.distance_to(nearest_point)
	var nearest_index = 0
	
	for i in range(patrol_points.size()):
		var distance = global_position.distance_to(patrol_points[i])
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_point = patrol_points[i]
			nearest_index = i
	
	# Move toward nearest point
	move_toward_target(nearest_point, patrol_speed, delta)
	
	# When reached, resume patrol
	if nearest_distance < 1.0:
		current_patrol_index = nearest_index
		current_state = State.PATROL
		print("Ghost: Resumed patrol")

func move_toward_target(target_pos: Vector3, move_speed: float, delta: float):
	"""Move character toward target position"""
	var direction = (target_pos - global_position).normalized()
	direction.y = 0  # Keep on ground level
	
	if direction.length() > 0.01:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		
		# Rotate to face movement direction
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 8.0 * delta)
	else:
		velocity.x = 0
		velocity.z = 0
	
	velocity.y = 0  # No gravity
	move_and_slide()

func check_player_detection():
	"""Check if player is in detection range AND visible"""
	if not player:
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	# If player in range and not already chasing
	if distance <= detection_range and current_state == State.PATROL:
		# Check line of sight before chasing
		if has_line_of_sight_to_player():
			print("Ghost: Player detected! Starting chase")
			enter_chase_state()

func has_line_of_sight_to_player() -> bool:
	"""Check if ghost can see player (no walls blocking)"""
	if not player:
		return false
	
	# Start and end positions for raycast
	var start_pos = global_position + Vector3(0, 1.5, 0)  # Ghost eye height
	var end_pos = player.global_position + Vector3(0, 1.0, 0)  # Player center
	
	# Create a raycast from ghost to player
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	
	# Check all layers
	query.collision_mask = 0xFFFFFFFF
	query.exclude = [self]  # Only exclude ghost itself
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var hit_object = result.collider
		
		# If we hit the player first, we can see them
		if hit_object == player:
			print("✓ Ghost sees player directly")
			return true
		
		# Check if hit object is part of player (like player's collision shape)
		if hit_object.get_parent() == player:
			print("✓ Ghost sees player (hit collision shape)")
			return true
		
		# Hit something else - it's a wall
		print("✗ Ghost vision blocked by: ", hit_object.name, " (type: ", hit_object.get_class(), ")")
		return false
	else:
		# Raycast didn't hit anything (shouldn't happen but means clear)
		print("? Raycast hit nothing (clear path?)")
		return true

func enter_chase_state():
	"""Enter chase state"""
	current_state = State.CHASE
	chase_timer = 0.0
	last_known_player_position = player.global_position

func enter_search_state():
	"""Enter search state"""
	current_state = State.SEARCH
	search_timer = 0.0

func next_patrol_point():
	"""Move to next patrol point"""
	current_patrol_index = (current_patrol_index + 1) % patrol_points.size()

func increase_speed(amount: float):
	"""Called by game manager to increase ghost speed"""
	patrol_speed += amount
	chase_speed += amount
	print("Ghost speed increased! Patrol: ", patrol_speed, " Chase: ", chase_speed)

func check_if_stuck(delta: float):
	"""Detect if ghost is stuck and teleport to nearest patrol point"""
	var movement = global_position.distance_to(last_position)
	
	if movement < 0.1:  # Barely moving
		stuck_timer += delta
		
		if stuck_timer >= stuck_threshold:
			print("Ghost stuck! Teleporting to nearest patrol point")
			teleport_to_nearest_patrol_point()
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0
	
	last_position = global_position

func teleport_to_nearest_patrol_point():
	"""Teleport ghost to nearest patrol point"""
	if patrol_points.size() == 0:
		return
	
	var nearest_point = patrol_points[0]
	var nearest_distance = global_position.distance_to(nearest_point)
	var nearest_index = 0
	
	for i in range(patrol_points.size()):
		var distance = global_position.distance_to(patrol_points[i])
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_point = patrol_points[i]
			nearest_index = i
	
	global_position = nearest_point
	current_patrol_index = nearest_index
	current_state = State.PATROL
	waiting = false
	print("Ghost teleported to patrol point ", nearest_index)

# Detection area callbacks
func _on_detection_area_entered(body):
	# Only auto-detect during patrol (other states check manually with line-of-sight)
	if body.is_in_group("player") and current_state == State.PATROL:
		if has_line_of_sight_to_player():
			enter_chase_state()

func _on_detection_area_exited(body):
	# Don't immediately give up when player leaves area
	# The chase/search state machines handle this better
	pass

# Debug visualization
func _process(delta):
	# Draw debug info in editor
	if Engine.is_editor_hint():
		return
	
	# Optional: Print state for debugging
	if OS.is_debug_build():
		pass  # Could show state above ghost
