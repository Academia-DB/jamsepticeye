extends CharacterBody3D

# Movement
@export var walk_speed: float = 3.0
@export var sprint_speed: float = 5.0
@export var rotation_speed: float = 12.0

# Health and regeneration
@export var max_health: int = 10
var current_health: int = 10
@export var health_regen_rate: float = 0.1
@export var health_regen_interval: float = 5.0
var regen_timer: float = 0.0

# Damage cooldown
var damage_cooldown: float = 0.0
@export var damage_cooldown_time: float = 1.0

# Pickup detection
@onready var pickup_area: Area3D = $PickupArea
var items_in_range: Array = []

# Key tracking
var keys_collected: int = 0
var has_exit_key: bool = false

# Signals
signal health_changed(new_health, max_health)
signal died()
signal item_picked_up(item)

func _ready():
	add_to_group("player")
	
	if pickup_area:
		pickup_area.body_entered.connect(_on_pickup_area_entered)
		pickup_area.body_exited.connect(_on_pickup_area_exited)
		print("Player pickup area connected")
	else:
		push_error("Player has no PickupArea child!")
	
	var damage_area = get_node_or_null("DamageArea")
	if damage_area:
		damage_area.area_entered.connect(_on_damage_area_entered)
	
	emit_signal("health_changed", current_health, max_health)

func _physics_process(delta):
	if damage_cooldown > 0:
		damage_cooldown -= delta
	
	handle_movement(delta)
	handle_pickup()

func handle_movement(delta):
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = Vector3(input_dir.x, 0, input_dir.y)
	var speed = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	
	if direction.length() > 0:
		direction = direction.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		
		var target_rotation = atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
	else:
		velocity.x = 0
		velocity.z = 0
	
	velocity.y = 0
	move_and_slide()

func handle_pickup():
	if Input.is_action_just_pressed("pickup"):
		print("E pressed! Items in range: ", items_in_range.size())
		if items_in_range.size() > 0:
			var closest_item = items_in_range[0]
			pickup_item(closest_item)
		else:
			print("  No items nearby")

func pickup_item(item):
	print("Picked up: ", item.name)
	
	# Check if it's a key using property existence check
	if "is_key" in item and item.is_key:
		keys_collected += 1
		
		if "key_number" in item and item.key_number == 4:
			has_exit_key = true
			print("*** EXIT KEY OBTAINED! ***")
		else:
			var key_num = item.key_number if "key_number" in item else keys_collected
			print("*** KEY ", key_num, " COLLECTED! ***")
	
	emit_signal("item_picked_up", item)
	items_in_range.erase(item)
	item.queue_free()

func take_damage(amount: int):
	if damage_cooldown > 0:
		return
	
	current_health -= amount
	current_health = max(0, current_health)
	damage_cooldown = damage_cooldown_time
	
	print("Player took ", amount, " damage. Health: ", current_health)
	emit_signal("health_changed", current_health, max_health)
	
	flash_damage()
	
	if current_health <= 0:
		die()

func flash_damage():
	pass

func die():
	print("Player died!")
	emit_signal("died")
	set_physics_process(false)

func heal(amount: int):
	current_health = min(current_health + amount, max_health)
	emit_signal("health_changed", current_health, max_health)

func _on_pickup_area_entered(body):
	print("PICKUP AREA DETECTED: ", body.name, " Type: ", body.get_class(), " Groups: ", body.get_groups())
	if body.is_in_group("pickable"):
		items_in_range.append(body)
		print("  → Added to pickup range")
	else:
		print("  → Not in 'pickable' group")

func _on_pickup_area_exited(body):
	if body.is_in_group("pickable"):
		items_in_range.erase(body)
		print("  → Removed from pickup range")

func _on_damage_area_entered(area):
	if area.is_in_group("hazard"):
		take_damage(area.damage_amount)
	elif area.is_in_group("enemy"):
		take_damage(1)
