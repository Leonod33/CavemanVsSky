extends Control

@onready var cave_health_bar = $HUDPanel/CaveHealthBar
@onready var wood_label       = $HUDPanel/ResourceBar/WoodLabel
@onready var stone_label      = $HUDPanel/ResourceBar/StoneLabel
@onready var meat_label       = $HUDPanel/ResourceBar/MeatLabel


# Wave / score labels under HUDPanel
@onready var wave_label  = $HUDPanel/WaveLabel
@onready var score_label = $HUDPanel/ScoreLabel

# --- Game Over UI -----------------------------------------------------------

@onready var game_over_panel     = $GameOverPanel
@onready var go_score_label      = $GameOverPanel/CenterContainer/Panel/VBoxContainer/ScoreLabel
@onready var go_highscore_label  = $GameOverPanel/CenterContainer/Panel/VBoxContainer/HighscoreLabel
@onready var go_wave_label       = $GameOverPanel/CenterContainer/Panel/VBoxContainer/WaveLabel
@onready var go_new_record_label = $GameOverPanel/CenterContainer/Panel/VBoxContainer/NewRecordLabel
@onready var go_retry_button     = $GameOverPanel/CenterContainer/Panel/VBoxContainer/HBoxContainer/RetryButton
@onready var go_title_button     = $GameOverPanel/CenterContainer/Panel/VBoxContainer/HBoxContainer/TitleButton

# --- Upgrade Panel UI -------------------------------------------------------

@onready var upgrade_panel: Control              = $UpgradePanel
@onready var up_meat_label: Label                = $UpgradePanel/CenterContainer/Panel/VBoxContainer/MeatLabel
@onready var up_title_label: Label               = $UpgradePanel/CenterContainer/Panel/VBoxContainer/TitleLabel
@onready var up_damage_button: Button            = $UpgradePanel/CenterContainer/Panel/VBoxContainer/DamageButton
@onready var up_fire_button: Button              = $UpgradePanel/CenterContainer/Panel/VBoxContainer/FireRateButton
@onready var up_info_label: Label                = $UpgradePanel/CenterContainer/Panel/VBoxContainer/InfoLabel
@onready var up_close_button: Button             = $UpgradePanel/CenterContainer/Panel/VBoxContainer/CloseButton


var caveman: Node = null
var game: Node = null


func _ready() -> void:
	# In Godot 4.3: keep HUD running always, GameOver only when paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	game_over_panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	# Upgrade panel should also be usable while the game is paused
	upgrade_panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	upgrade_panel.visible = false
	up_info_label.text = ""

	game = get_tree().current_scene

	# Find the caveman in the world (fallback: group lookup)
	if game and game.has_node("World/GroundLayer/Caveman"):
		caveman = game.get_node("World/GroundLayer/Caveman")
	else:
		# in case we ever move the node, group gives us a backup
		var c = get_tree().get_first_node_in_group("caveman")
		if c:
			caveman = c

	# Hide game over panel initially
	game_over_panel.visible = false

	# Buttons must respond even over the dim background
	# (make sure ColorRect.Mouse.Filter = Ignore in the editor)
	go_retry_button.pressed.connect(_on_retry_button_pressed)
	go_title_button.pressed.connect(_on_title_button_pressed)

	# Connect upgrade panel buttons
	up_damage_button.pressed.connect(_on_damage_upgrade_pressed)
	up_fire_button.pressed.connect(_on_fire_upgrade_pressed)
	up_close_button.pressed.connect(_on_upgrade_close_pressed)

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


# --- Upgrade menu control ---------------------------------------------------

func open_upgrade_menu() -> void:
	print("[HUD] open_upgrade_menu() called")

	if caveman == null:
		# try to refind in case of reload
		var c = get_tree().get_first_node_in_group("caveman")
		if c:
			caveman = c

	if caveman == null:
		print("[HUD] No caveman found, cannot open upgrade menu.")
		return

	_refresh_upgrade_panel()
	upgrade_panel.visible = true
	up_close_button.grab_focus()

	# Pause the game while upgrading, but HUD + panel still run
	get_tree().paused = true


func _refresh_upgrade_panel() -> void:
	if caveman == null:
		up_title_label.text = "No caveman found!"
		up_meat_label.text = "Meat: ?"
		up_damage_button.disabled = true
		up_fire_button.disabled = true
		return

	# Title + meat
	up_title_label.text = "Toolshed Upgrades"
	up_meat_label.text = "Meat: %d" % caveman.meat

	# Damage upgrade info
	var dmg_lvl    = caveman.tower_damage_level
	var dmg_max    = caveman.tower_damage_max_level
	var dmg_cost   = caveman.get_tower_damage_cost()

	up_damage_button.text = "Stronger Rocks (Lv %d/%d) - Cost: %d" % [dmg_lvl, dmg_max, dmg_cost]
	up_damage_button.disabled = not caveman.can_buy_tower_damage()

	# Fire rate upgrade info
	var fr_lvl     = caveman.tower_fire_rate_level
	var fr_max     = caveman.tower_fire_rate_max_level
	var fr_cost    = caveman.get_tower_fire_rate_cost()

	up_fire_button.text = "Faster Throwing (Lv %d/%d) - Cost: %d" % [fr_lvl, fr_max, fr_cost]
	up_fire_button.disabled = not caveman.can_buy_tower_fire_rate()


func _on_damage_upgrade_pressed() -> void:
	if caveman == null:
		return

	if caveman.buy_tower_damage():
		up_info_label.text = "Your towers hit harder!"
	else:
		up_info_label.text = "Can't buy that (not enough meat or maxed)."

	# Refresh both the panel & main HUD counts
	_refresh_upgrade_panel()
	_update_labels()


func _on_fire_upgrade_pressed() -> void:
	if caveman == null:
		return

	if caveman.buy_tower_fire_rate():
		up_info_label.text = "Your towers throw faster!"
	else:
		up_info_label.text = "Can't buy that (not enough meat or maxed)."

	_refresh_upgrade_panel()
	_update_labels()


func _on_upgrade_close_pressed() -> void:
	upgrade_panel.visible = false
	up_info_label.text = ""
	get_tree().paused = false


# --- Game Over --------------------------------------------------------------

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
