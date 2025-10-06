extends CanvasLayer

# References
@onready var health_orb: TextureRect = $HealthOrb
@onready var inventory_bar: HBoxContainer = $InventoryContainer/InventoryBar

# Health orb settings
@export var max_orb_size: float = 100.0
@export var min_orb_size: float = 20.0

# Inventory settings
var inventory_items: Array = []
var inventory_slot_nodes: Array = []

func _ready():
	# Connect to player signals
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_player_health_changed)
		player.item_picked_up.connect(_on_item_picked_up)

func create_inventory_slot(index: int) -> Panel:
	var slot = Panel.new()
	slot.custom_minimum_size = Vector2(64, 64)
	slot.name = "Slot" + str(index)
	
	var texture_rect = TextureRect.new()
	texture_rect.name = "ItemIcon"
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.anchor_right = 1.0
	texture_rect.anchor_bottom = 1.0
	slot.add_child(texture_rect)
	
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
	var health_percent = float(current_health) / float(max_health)
	var new_size = lerp(min_orb_size, max_orb_size, health_percent)
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(health_orb, "custom_minimum_size", Vector2(new_size, new_size), 0.3)
	tween.parallel().tween_property(health_orb, "size", Vector2(new_size, new_size), 0.3)
	
	var color = Color.WHITE
	if health_percent <= 0.25:
		color = Color.RED
	elif health_percent <= 0.5:
		color = Color.ORANGE
	
	tween.parallel().tween_property(health_orb, "modulate", color, 0.2)

func _on_item_picked_up(item):
	var slot_index = inventory_items.size()
	var slot = create_inventory_slot(slot_index)
	inventory_bar.add_child(slot)
	inventory_slot_nodes.append(slot)
	inventory_items.append(item)
	
	var icon_node = slot.get_node("ItemIcon")
	
	# Check if item has icon property
	if "icon" in item and item.icon:
		icon_node.texture = item.icon
	
	# Animate
	icon_node.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(icon_node, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(icon_node, "scale", Vector2(1.2, 1.2), 0.15)
	tween.tween_property(icon_node, "scale", Vector2.ONE, 0.15)

func add_item_to_slot(slot_index: int, item):
	inventory_items[slot_index] = item
	
	var slot = inventory_bar.get_child(slot_index)
	var icon_node = slot.get_node("ItemIcon")
	
	if "icon" in item and item.icon:
		icon_node.texture = item.icon
	
	icon_node.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(icon_node, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(icon_node, "scale", Vector2(1.2, 1.2), 0.15)
	tween.tween_property(icon_node, "scale", Vector2.ONE, 0.15)

func remove_item_from_slot(slot_index: int):
	if slot_index < 0 or slot_index >= inventory_items.size():
		return
	
	inventory_items.remove_at(slot_index)
	
	if slot_index < inventory_slot_nodes.size():
		var slot = inventory_slot_nodes[slot_index]
		inventory_slot_nodes.remove_at(slot_index)
		slot.queue_free()

func get_item_at_slot(slot_index: int):
	if slot_index < 0 or slot_index >= inventory_items.size():
		return null
	return inventory_items[slot_index]
