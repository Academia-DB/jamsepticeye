extends CharacterBody3D

# Movement
@export var walk_speed: float = 3.0
@export var sprint_speed: float = 5.0
@export var rotation_speed: float = 12.0

# Health
@export var max_health: int = 10
var current_health: int = 10

# Damage cooldown to prevent rapid repeated damage
var damage_cooldown: float = 0.0
@export var damage_cooldown_time: float = 1.0

# Pickup detection
@onready var pickup_area: Area3D = $PickupArea
var items_in_range: Array = []

# Note: DamageArea is optional - add it if you want automatic hazard detection
# Otherwise, hazards can call take_damage() directly when player enters them

# Signals for UI and game events
signal health_changed(new_health, max_health)
signal died()
signal item_picked_up(item)

func _ready():
	# Add player to group so HUD can find it
	add_to_group("player")
	
	# Connect PickupArea signals if it exists
	if pickup_area:
		pickup_area.body_entered.connect(_on_pickup_area_entered)
		pickup_area.body_exited.connect(_on_pickup_area_exited)
		pickup_area.area_entered.connect(_on_pickup_area_entered)
		pickup_area.area_exited.connect(_on_pickup_area_exited)
	
	# Connect DamageArea signals if it exists
	var damage_area = get_node_or_null("DamageArea")
	if damage_area:
		damage_area.area_entered.connect(_on_damage_area_entered)
	
	emit_signal("health_changed", current_health, max_health)

func _physics_process(delta):
	# Update damage cooldown
	if damage_cooldown > 0:
		damage_cooldown -= delta
	
	handle_movement(delta)
	handle_pickup()

func handle_movement(delta):
	# Get input direction
	var input_dir = Input.get_vector("left", "right", "up", "down")
	
	# Convert to 3D isometric direction
	# For Yomawari/Corpse Party style, we use simple direct mapping
	var direction = Vector3(input_dir.x, 0, input_dir.y)
	
	# Check if sprinting
	var speed = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	
	# Set velocity directly (no acceleration for arcade feel)
	if direction.length() > 0:
		direction = direction.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		
		# Rotate character to face movement direction
		var target_rotation = atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
	else:
		velocity.x = 0
		velocity.z = 0
	
	# Keep Y velocity at 0 (no gravity, flat movement)
	velocity.y = 0
	
	move_and_slide()

func handle_pickup():
	if Input.is_action_just_pressed("pickup") and items_in_range.size() > 0:
		# Pick up the closest item
		var closest_item = items_in_range[0]
		pickup_item(closest_item)

func pickup_item(item):
	print("Picked up: ", item.name)
	emit_signal("item_picked_up", item)
	
	# Remove from tracking
	items_in_range.erase(item)
	
	# Add to inventory (implement later)
	# InventoryManager.add_item(item.item_data)
	
	# Remove from world
	item.queue_free()

func take_damage(amount: int):
	# Check damage cooldown
	if damage_cooldown > 0:
		return
	
	current_health -= amount
	current_health = max(0, current_health)
	damage_cooldown = damage_cooldown_time
	
	print("Player took ", amount, " damage. Health: ", current_health)
	emit_signal("health_changed", current_health, max_health)
	
	# Visual feedback (flash, shake, etc.)
	flash_damage()
	
	if current_health <= 0:
		die()

func flash_damage():
	# Simple damage flash - make this fancier later
	# You could modulate the player's material here
	pass

func die():
	print("Player died!")
	emit_signal("died")
	# Handle death (game over screen, respawn, etc.)
	# For now, just disable movement
	set_physics_process(false)

func heal(amount: int):
	current_health = min(current_health + amount, max_health)
	emit_signal("health_changed", current_health, max_health)

# Area3D signal handlers
func _on_pickup_area_entered(body):
	if body.is_in_group("pickable"):
		items_in_range.append(body)

func _on_pickup_area_exited(body):
	if body.is_in_group("pickable"):
		items_in_range.erase(body)

# For damage from terrain or enemies
func _on_damage_area_entered(area):
	if area.is_in_group("hazard"):
		take_damage(area.damage_amount)
	elif area.is_in_group("enemy"):
		take_damage(1)  # Or get damage from enemy's property
