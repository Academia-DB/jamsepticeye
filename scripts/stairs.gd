# stairway_teleport.gd
# Attach to each stairway Area3D
extends Area3D

@export var destination_stairway: Area3D  # Link to the other stairway
@export var teleport_offset: Vector3 = Vector3(0, 0, 2)  # Offset from destination center
@export var cooldown_time: float = 1.0  # Prevent rapid back-and-forth

var players_on_cooldown: Dictionary = {}

func _ready():
	body_entered.connect(_on_body_entered)

func _process(delta):
	# Update cooldowns
	for player in players_on_cooldown.keys():
		players_on_cooldown[player] -= delta
		if players_on_cooldown[player] <= 0:
			players_on_cooldown.erase(player)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Check cooldown
		if body in players_on_cooldown:
			return  # Still on cooldown
		
		teleport_player(body)

func teleport_player(player: Node3D):
	"""Teleport player to destination stairway"""
	if not destination_stairway:
		push_warning("No destination stairway set!")
		return
	
	# Calculate destination position
	var dest_pos = destination_stairway.global_position + teleport_offset
	
	# Teleport
	player.global_position = dest_pos
	
	# Add cooldown to prevent immediate return teleport
	players_on_cooldown[player] = cooldown_time
	
	# Optional: Play sound effect
	print("Player teleported from ", name, " to ", destination_stairway.name)
	
	# Optional: Visual effect
	spawn_teleport_effect(player.global_position)
	spawn_teleport_effect(dest_pos)

func spawn_teleport_effect(position: Vector3):
	"""Optional: Spawn particle effect at teleport location"""
	# You can add GPUParticles3D here for visual flair
	pass
