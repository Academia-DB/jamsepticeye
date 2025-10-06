extends Node3D

@export var rooms: Array[Node3D] = []
@export var starting_room: Node3D

var current_room: Node3D = null

func _ready():
	setup_rooms()

func setup_rooms():
	for room in rooms:
		var trigger = room.get_node_or_null("Trigger")
		
		if trigger and trigger is Area3D:
			trigger.body_entered.connect(_on_room_entered.bind(room))
			trigger.body_exited.connect(_on_room_exited.bind(room))
			print("✓ Trigger connected: ", room.name)
		else:
			push_warning("⚠ No trigger: ", room.name)
		
		# Hide all rooms completely (geometry + lights)
		hide_room(room)
	
	# Show starting room
	if starting_room:
		current_room = starting_room
		show_room(starting_room)
		print("=== STARTING IN: ", starting_room.name, " ===")

func _on_room_entered(body: Node3D, room: Node3D):
	if not body.is_in_group("player"):
		return
	
	print(">>> ENTERED: ", room.name)
	
	if current_room == room:
		return
	
	# Hide old room
	if current_room:
		hide_room(current_room)
	
	# Show new room
	current_room = room
	show_room(room)

func _on_room_exited(body: Node3D, room: Node3D):
	if not body.is_in_group("player"):
		return
	
	print("<<< EXITED: ", room.name)

func show_room(room: Node3D):
	"""Show all geometry and lights in room"""
	set_room_visibility(room, true)

func hide_room(room: Node3D):
	"""Hide all geometry and lights in room"""
	set_room_visibility(room, false)

func set_room_visibility(node: Node3D, visible: bool):
	"""Recursively set visibility of all visual elements"""
	# Skip the Trigger node - it should always be active
	if node is Area3D and node.name == "Trigger":
		return
	
	# Set visibility for visual nodes
	if node is VisualInstance3D:
		node.visible = visible
	
	if node is Light3D:
		node.visible = visible
	
	# Recurse through children
	for child in node.get_children():
		if child is Node3D:
			set_room_visibility(child, visible)
