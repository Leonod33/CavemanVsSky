extends Control

@onready var start_button: Button = $StartButton
@onready var quit_button: Button = $QuitButton 

func _ready() -> void:
	# Make sure buttons can be focused
	start_button.focus_mode = Control.FOCUS_ALL
	quit_button.focus_mode = Control.FOCUS_ALL

	# Start with StartButton selected
	start_button.grab_focus()

	# (existing connections)
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world/Game_CavemanVsSky.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
