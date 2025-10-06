# exit_door.gd
# Attach to an Area3D node at the exit location
extends Area3D

@export var win_scene_path: String = "res://win_screen.tscn"
@export var locked_message: String = "The door is locked. Find the exit key!"

func _ready():
	body_entered.connect(_on_body_entered)
	add_to_group("exit_door")

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Check if player has the exit key
		if body.has_exit_key:
			print("=== PLAYER ESCAPED! VICTORY! ===")
			# Load win screen
			get_tree().change_scene_to_file(win_scene_path)
		else:
			print(locked_message)
			# Optional: Show UI message to player
