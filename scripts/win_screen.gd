# win_screen.gd
# Attach to root Control node of win_screen.tscn
extends Control

@onready var restart_button = $VBoxContainer/RestartButton
@onready var quit_button = $VBoxContainer/QuitButton
@onready var title_label = $VBoxContainer/TitleLabel

func _ready():
	# Connect buttons
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	
	# Focus restart button for keyboard navigation
	if restart_button:
		restart_button.grab_focus()

func _on_restart_pressed():
	# Restart the game
	get_tree().change_scene_to_file("res://main.tscn")

func _on_quit_pressed():
	# Return to main menu
	get_tree().change_scene_to_file("res://main_menu.tscn")
