extends Area3D

# Hazard properties
@export var damage_amount: int = 1
@export var damage_type: String = "environmental"  # fire, poison, spikes, etc.

# Damage timing
@export var continuous_damage: bool = false  # If true, damages while standing in it
@export var damage_interval: float = 1.0  # How often to damage if continuous

# Visual effects
@export var warning_color: Color = Color.RED

# Tracking
var players_inside: Array = []
var damage_timers: Dictionary = {}

func _ready():
	# Add to hazard group
	add_to_group("hazard")
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta):
	if continuous_damage:
		for player in players_inside:
			if player not in damage_timers:
				damage_timers[player] = 0.0
			
			damage_timers[player] += delta
			
			if damage_timers[player] >= damage_interval:
				damage_player(player)
				damage_timers[player] = 0.0

func _on_body_entered(body):
	if body.is_in_group("player"):
		players_inside.append(body)
		
		# Immediate damage if not continuous
		if not continuous_damage:
			damage_player(body)
		
		# Visual feedback
		show_warning_effect()

func _on_body_exited(body):
	if body.is_in_group("player"):
		players_inside.erase(body)
		if body in damage_timers:
			damage_timers.erase(body)

func damage_player(player):
	if player.has_method("take_damage"):
		player.take_damage(damage_amount)
		print("Hazard dealt ", damage_amount, " damage to player")

func show_warning_effect():
	# Optional: Add visual warning (particle effect, color flash, etc.)
	# For now, just print
	print("Player entered hazard zone!")

# Optional: Specific hazard behaviors
func set_spike_hazard():
	damage_type = "spikes"
	continuous_damage = false
	damage_amount = 2

func set_pit_hazard():
	damage_type = "pit"
	continuous_damage = false
	damage_amount = 3  # Falling in a hole hurts more!

func set_enemy_projectile():
	damage_type = "projectile"
	continuous_damage = false
	damage_amount = 1

# For enemy collision damage, this would be on the enemy itself, not a separate hazard
