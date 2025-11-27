extends Node2D

@export var interact_action: StringName = "interact"  # same action you use for chop/build
@export var interact_radius: float = 32.0             # tweak to taste

var caveman: Node2D = null

@onready var prompt_label: Label = $PromptLabel


func _ready() -> void:
	var game := get_tree().current_scene
	if game and game.has_node("World/GroundLayer/Caveman"):
		caveman = game.get_node("World/GroundLayer/Caveman")

	if prompt_label:
		prompt_label.visible = false


func _process(_delta: float) -> void:
	if caveman == null:
		return

	# Simple distance check to see if Caveman is close enough
	var dist := global_position.distance_to(caveman.global_position)
	var in_range := dist <= interact_radius

	if prompt_label:
		prompt_label.visible = in_range

	if in_range and Input.is_action_just_pressed(interact_action):
		_open_upgrade_menu()


func _open_upgrade_menu() -> void:
	var game := get_tree().current_scene
	if game and game.has_node("UI"):
		var ui := game.get_node("UI")
		if ui.has_method("open_upgrade_menu"):
			ui.open_upgrade_menu()
		else:
			print("UI has no open_upgrade_menu() yet (stub).")
