extends CanvasLayer

# References
@onready var health_orb: TextureRect = $HealthOrb
@onready var inventory_bar: HBoxContainer = $InventoryContainer/InventoryBar

# Health orb settings
@export var max_orb_size: float = 100.0
@export var min_orb_size: float = 20.0

# Inventory settings
@export var inventory_slots: int = 8
var inventory_items: Array = []

# We'll create slots programmatically, no need for a separate scene

func _ready():
	setup_inventory_bar()
	
	# Connect to player signals
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_player_health_changed)
		player.item_picked_up.connect(_on_item_picked_up)

func setup_inventory_bar():
	# Clear existing slots
	for child in inventory_bar.get_children():
		child.queue_free()
	
	# Create inventory slots
	for i in range(inventory_slots):
		var slot = create_inventory_slot(i)
		inventory_bar.add_child(slot)
		inventory_items.append(null)

func create_inventory_slot(index: int) -> Panel:
	var slot = Panel.new()
	slot.custom_minimum_size = Vector2(64, 64)
	slot.name = "Slot" + str(index)
	
	# Add a TextureRect for the item icon
	var texture_rect = TextureRect.new()
	texture_rect.name = "ItemIcon"
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.anchor_right = 1.0
	texture_rect.anchor_bottom = 1.0
	slot.add_child(texture_rect)
	
	# Add a label for item count (optional)
	var label = Label.new()
	label.name = "CountLabel"
	label.text = ""
	label.anchor_left = 0.7
	label.anchor_top = 0.7
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	slot.add_child(label)
	
	return slot

func _on_player_health_changed(current_health: int, max_health: int):
	# Calculate size based on health percentage
	var health_percent = float(current_health) / float(max_health)
	var new_size = lerp(min_orb_size, max_orb_size, health_percent)
	
	# Animate the size change
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(health_orb, "custom_minimum_size", Vector2(new_size, new_size), 0.3)
	tween.parallel().tween_property(health_orb, "size", Vector2(new_size, new_size), 0.3)
	
	# Optional: Change color based on health
	var color = Color.WHITE
	if health_percent <= 0.25:
		color = Color.RED
	elif health_percent <= 0.5:
		color = Color.ORANGE
	
	tween.parallel().tween_property(health_orb, "modulate", color, 0.2)

func _on_item_picked_up(item):
	# Find first empty slot
	for i in range(inventory_items.size()):
		if inventory_items[i] == null:
			add_item_to_slot(i, item)
			break

func add_item_to_slot(slot_index: int, item):
	inventory_items[slot_index] = item
	
	# Update visual
	var slot = inventory_bar.get_child(slot_index)
	var icon = slot.get_node("ItemIcon")
	
	# Assuming item has an icon texture
	if item.has("icon"):
		icon.texture = item.icon
	
	# Animate the item appearing
	icon.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(icon, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(icon, "scale", Vector2(1.2, 1.2), 0.15)
	tween.tween_property(icon, "scale", Vector2.ONE, 0.15)

func remove_item_from_slot(slot_index: int):
	if slot_index < 0 or slot_index >= inventory_items.size():
		return
	
	inventory_items[slot_index] = null
	
	var slot = inventory_bar.get_child(slot_index)
	var icon = slot.get_node("ItemIcon")
	icon.texture = null

func get_item_at_slot(slot_index: int):
	if slot_index < 0 or slot_index >= inventory_items.size():
		return null
	return inventory_items[slot_index]
