# main_menu.gd
# Attach to MainMenu scene Control node
extends Control

@onready var start_button = $VBoxContainer/StartButton
@onready var quit_button = $VBoxContainer/QuitButton

func _ready():
	# Connect buttons
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	
	# Focus start button for keyboard navigation
	if start_button:
		start_button.grab_focus()

func _on_start_pressed():
	# Load main game scene
	get_tree().change_scene_to_file("res://scene/main.tscn")

func _on_quit_pressed():
	get_tree().quit()
