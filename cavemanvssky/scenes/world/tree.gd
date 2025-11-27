extends Node2D
@onready var work_bar: ProgressBar = $WorkBar
@onready var anim_player: AnimationPlayer = $AnimationPlayer

var _max_hits: int = 1

func setup(max_hits: int) -> void:
	_max_hits = max_hits
	if work_bar:
		work_bar.max_value = max_hits
		work_bar.value = 0
		work_bar.visible = false

func update_progress(current_hits: int) -> void:
	if work_bar:
		work_bar.value = current_hits
		work_bar.visible = true
	if anim_player:
		anim_player.play("shake")

func play_collected() -> void:
	if work_bar:
		work_bar.visible = false
	if anim_player:
		anim_player.play("collected")

func clear_progress() -> void:
	if work_bar:
		work_bar.visible = false
