extends StaticBody3D

# Item properties
@export var item_name: String = "Item"
@export var icon: Texture2D  # Assign in the editor
@export var item_description: String = ""

# Visual feedback
@export var hover_height: float = 0.3
@export var bob_speed: float = 2.0
@export var rotate_speed: float = 1.0

var initial_y: float
var time_passed: float = 0.0

func _ready():
	# Add to pickable group
	add_to_group("pickable")
	
	# Store initial position
	initial_y = position.y

func _process(delta):
	time_passed += delta
	
	# Bob up and down
	position.y = initial_y + sin(time_passed * bob_speed) * hover_height
	
	# Rotate slowly
	rotate_y(rotate_speed * delta)

# Optional: Highlight when player is nearby
func _on_player_nearby():
	# Add glow or scale effect
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ONE * 1.2, 0.3)

func _on_player_left():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ONE, 0.3)
