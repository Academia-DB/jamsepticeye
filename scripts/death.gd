extends Control

@onready var restart_button = $VBoxContainer/Restart
@onready var menu_button = $VBoxContainer/MainMenu

func _ready():
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_main_menu_pressed)
	restart_button.grab_focus()	

func _on_main_menu_pressed():
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")

func _on_restart_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/main.tscn")
