# game_manager.gd
# Attach to MainScene - controls entire game flow
extends Node3D

# References
@export var player: CharacterBody3D
@export var ghost_spawner: Node3D  # The ghost spawner script
@export var key_scene: PackedScene  # Your key item scene

# Key spawning
@export var key_1_spawn_points: Array[Marker3D] = []  # First key possible locations
@export var key_2_spawn_points: Array[Marker3D] = []  # Second key possible locations  

# Door walls (blocks that disappear)
@export var doors_wave_1: Array[Node3D] = []  # Doors that open after key 1
@export var doors_wave_2: Array[Node3D] = []  # Doors that open after key 2
@export var doors_wave_3: Array[Node3D] = []  # Final 3 room doors (one has exit key)

# Exit key (final key that opens exit)
@export var exit_key_spawn_points: Array[Marker3D] = []  # Last 3 rooms

# Ghost speed increase
@export var ghost_speed_increase: float = 0.5

# Game state
var current_wave: int = 0  # 0=start, 1=after key1, 2=after key2, 3=after key3
var active_key: Node3D = null
var ghost: Node3D = null

func _ready():
	# Wait a frame for everything to load
	await get_tree().process_frame
	
	# Get ghost reference
	if ghost_spawner:
		ghost = ghost_spawner.get_ghost()
	
	# Connect to player signals
	if player:
		player.item_picked_up.connect(_on_item_picked_up)
	
	# Start game
	start_game()

func start_game():
	"""Initialize game state"""
	print("=== GAME START ===")
	
	# All doors start closed except wave 1
	close_all_doors()
	
	# Spawn first key
	spawn_key_wave(1)

func spawn_key_wave(wave_number: int):
	"""Spawn a key for the given wave"""
	var spawn_points: Array[Marker3D] = []
	
	match wave_number:
		1:
			spawn_points = key_1_spawn_points
		2:
			spawn_points = key_2_spawn_points
		3:
			spawn_points = exit_key_spawn_points
	
	if spawn_points.size() == 0:
		push_error("No spawn points for wave ", wave_number)
		return
	
	# Pick random spawn
	var random_index = randi() % spawn_points.size()
	var spawn_point = spawn_points[random_index]
	
	# Spawn key
	if key_scene:
		active_key = key_scene.instantiate()
		add_child(active_key)
		active_key.global_position = spawn_point.global_position
		
		# Set key metadata
		active_key.set_meta("wave", wave_number)
		
		print("Key ", wave_number, " spawned at: ", spawn_point.name)
	else:
		push_error("Key scene not assigned!")

func _on_item_picked_up(item):
	"""Called when player picks up any item"""
	# Check if it's a key
	if item == active_key:
		var wave = item.get_meta("wave", 0)
		print("Key ", wave, " collected!")
		
		# Progress to next wave
		advance_wave(wave)

func advance_wave(completed_wave: int):
	"""Progress game after collecting key"""
	current_wave = completed_wave
	
	match completed_wave:
		1:
			print("=== WAVE 2: Opening new areas ===")
			open_doors(doors_wave_1)
			spawn_key_wave(2)
			increase_ghost_speed()
			
		2:
			print("=== WAVE 3: Opening more areas ===")
			open_doors(doors_wave_2)
			spawn_key_wave(3)
			increase_ghost_speed()
			
		3:
			print("=== FINAL WAVE: Opening last 3 rooms ===")
			open_doors(doors_wave_3)
			spawn_key_wave(4)  # Exit key
			increase_ghost_speed()
			
		4:
			print("=== EXIT KEY COLLECTED! Find the exit! ===")
			# Exit key collected, player can now escape
			# Exit door should check for this key

func open_doors(door_array: Array[Node3D]):
	"""Open (remove) door walls"""
	for door in door_array:
		if door:
			# Animate door disappearing
			var tween = create_tween()
			tween.tween_property(door, "scale", Vector3.ZERO, 0.5)
			tween.tween_callback(door.queue_free)
			print("Opening door: ", door.name)

func close_all_doors():
	"""Ensure all doors are closed at start"""
	# Doors wave 2 and 3 should be visible/blocking
	for door in doors_wave_2:
		if door:
			door.visible = true
			door.scale = Vector3.ONE
	
	for door in doors_wave_3:
		if door:
			door.visible = true
			door.scale = Vector3.ONE

func increase_ghost_speed():
	"""Make ghost faster"""
	if ghost and ghost.has_method("increase_speed"):
		ghost.increase_speed(ghost_speed_increase)
		print("Ghost speed increased!")
	elif ghost:
		# Manually increase speeds if method doesn't exist
		if ghost.has("patrol_speed"):
			ghost.patrol_speed += ghost_speed_increase
		if ghost.has("chase_speed"):
			ghost.chase_speed += ghost_speed_increase
		print("Ghost speed increased to: patrol=", ghost.patrol_speed, " chase=", ghost.chase_speed)

func get_current_wave() -> int:
	"""Returns current progression wave"""
	return current_wave
