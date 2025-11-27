extends Control

@onready var cave_health_bar = $HUDPanel/CaveHealthBar
@onready var wood_label       = $HUDPanel/ResourceBar/WoodLabel
@onready var stone_label      = $HUDPanel/ResourceBar/StoneLabel
@onready var meat_label       = $HUDPanel/ResourceBar/MeatLabel


# Wave / score labels under HUDPanel
@onready var wave_label  = $HUDPanel/WaveLabel
@onready var score_label = $HUDPanel/ScoreLabel

# --- Game Over UI (direct paths, matching your screenshot) ------------------

@onready var game_over_panel     = $GameOverPanel
@onready var go_score_label      = $GameOverPanel/CenterContainer/Panel/VBoxContainer/ScoreLabel
@onready var go_highscore_label  = $GameOverPanel/CenterContainer/Panel/VBoxContainer/HighscoreLabel
@onready var go_wave_label       = $GameOverPanel/CenterContainer/Panel/VBoxContainer/WaveLabel
@onready var go_new_record_label = $GameOverPanel/CenterContainer/Panel/VBoxContainer/NewRecordLabel
@onready var go_retry_button     = $GameOverPanel/CenterContainer/Panel/VBoxContainer/HBoxContainer/RetryButton
@onready var go_title_button     = $GameOverPanel/CenterContainer/Panel/VBoxContainer/HBoxContainer/TitleButton

var caveman: Node = null
var game: Node = null


func _ready() -> void:
	# In Godot 4.3: keep HUD running always, GameOver only when paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	game_over_panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	game = get_tree().current_scene

	# Find the caveman in the world
	if game and game.has_node("World/GroundLayer/Caveman"):
		caveman = game.get_node("World/GroundLayer/Caveman")

	# Hide game over panel initially
	game_over_panel.visible = false

	# Buttons must respond even over the dim background
	# (make sure ColorRect.Mouse.Filter = Ignore in the editor)
	go_retry_button.pressed.connect(_on_retry_button_pressed)
	go_title_button.pressed.connect(_on_title_button_pressed)

	_update_labels()


func _process(_delta: float) -> void:
	if caveman == null:
		return

	_update_labels()


func _update_labels() -> void:
	# Resources (just numbers; icons explain what is what)
	wood_label.text = str(caveman.wood)
	stone_label.text = str(caveman.stone)
	meat_label.text = str(caveman.meat)


	# Wave + score from the game node
	if game:
		if "current_wave" in game:
			wave_label.text = "Wave: %d" % game.current_wave
		if "score" in game:
			score_label.text = "Score: %d" % game.score


func update_cave_health(current: int, max_health: int) -> void:
	if cave_health_bar == null:
		return

	cave_health_bar.max_value = max_health
	cave_health_bar.value = current


# Called from game_caveman_vs_sky.gd when wave/score change
func update_wave_and_score(_wave: int, _score: int) -> void:
	# Just re-read from the game node
	_update_labels()


func open_upgrade_menu() -> void:
	print("[HUD] open_upgrade_menu() called – TODO: show upgrade UI here")
	# Next step: show a proper UpgradePanel and list of tower upgrades.



# Called from game_caveman_vs_sky.gd at game over
func show_game_over(final_score: int, best_score: int, final_wave: int, is_new_record: bool) -> void:
	print("[HUD] Showing Game Over screen")

	go_score_label.text     = "Score: %d" % final_score
	go_highscore_label.text = "High Score: %d" % best_score
	go_wave_label.text      = "Wave Reached: %d" % final_wave
	go_new_record_label.visible = is_new_record

	# Hide HUD, show game over
	$HUDPanel.visible = false
	game_over_panel.visible = true

	# So keyboard/gamepad focus starts on Retry
	go_retry_button.grab_focus()


func _on_retry_button_pressed() -> void:
	print("[HUD] Retry button pressed")
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_title_button_pressed() -> void:
	print("[HUD] Title button pressed")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
