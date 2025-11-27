extends Node2D

@export var bird_scene: PackedScene
@export var bird_spawn_interval: float = 3.0  # base seconds between birds (wave 1)
@export var bird_spawn_y: float = 260.0       # height of the flight path above the wall

@export var wall_max_health: int = 10
var wall_health: int

@export var starting_rocks: int = 10

# --- Wave / difficulty config ---
enum GameState { PLAYING, BETWEEN_WAVES, GAME_OVER }
var state: int = GameState.PLAYING

@export var base_birds_per_wave: int = 4
@export var birds_per_wave_increment: int = 2

@export var time_between_waves: float = 4.0

@export var min_spawn_interval: float = 0.8
@export var spawn_interval_decrease: float = 0.3

var current_wave: int = 1
var birds_to_spawn_this_wave: int = 0
var birds_spawned_in_wave: int = 0
var birds_alive: int = 0

var _bird_timer: float = 0.0
var _time_until_next_wave: float = 0.0
var _current_spawn_interval: float = 0.0

# --- Scoring / highscore ---
var score: int = 0
@export var score_per_bird: int = 10
@export var score_per_wave_cleared: int = 50

var highscore: int = 0
const SAVE_PATH := "user://caveman_vs_sky_highscore.dat"

@onready var sky_layer: Node2D = $World/SkyLayer
@onready var caveman: Node2D   = $World/GroundLayer/Caveman
@onready var ui: Control       = $UI


func _ready() -> void:
	print("[Caveman vs Sky] Game scene ready")

	_load_highscore()

	wall_health = wall_max_health

	if ui and ui.has_method("update_cave_health"):
		ui.update_cave_health(wall_health, wall_max_health)

	# Initialise shared stone/rock resource on the Caveman
	if caveman:
		caveman.stone = starting_rocks

	# Wave 1 setup
	_current_spawn_interval = bird_spawn_interval
	_start_wave(1)


func _process(delta: float) -> void:
	match state:
		GameState.PLAYING:
			_update_bird_spawning(delta)
		GameState.BETWEEN_WAVES:
			_time_until_next_wave -= delta
			if _time_until_next_wave <= 0.0:
				_start_wave(current_wave + 1)
		GameState.GAME_OVER:
			pass


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")


# --- Wave / spawn helpers ----------------------------------------------------

func _start_wave(wave_number: int) -> void:
	current_wave = wave_number

	birds_to_spawn_this_wave = base_birds_per_wave + (wave_number - 1) * birds_per_wave_increment
	birds_spawned_in_wave = 0

	_current_spawn_interval = max(
		min_spawn_interval,
		bird_spawn_interval - (wave_number - 1) * spawn_interval_decrease
	)

	_bird_timer = 0.5
	state = GameState.PLAYING

	print("Starting wave %d | birds: %d | spawn interval: %.2f"
		% [current_wave, birds_to_spawn_this_wave, _current_spawn_interval])

	_update_wave_and_score()


func _update_bird_spawning(delta: float) -> void:
	if birds_spawned_in_wave >= birds_to_spawn_this_wave:
		if birds_alive <= 0:
			_on_wave_cleared()
		return

	_bird_timer -= delta
	if _bird_timer <= 0.0:
		_bird_timer = _current_spawn_interval
		_spawn_bird()


func _on_wave_cleared() -> void:
	print("Wave %d cleared!" % current_wave)
	score += score_per_wave_cleared
	state = GameState.BETWEEN_WAVES
	_time_until_next_wave = time_between_waves
	_update_wave_and_score()


func _on_bird_died() -> void:
	birds_alive = max(0, birds_alive - 1)
	score += score_per_bird
	
		# --- NEW: award meat for upgrades ---
	if caveman:
		caveman.meat += 1
		print("Meat collected! Total meat:", caveman.meat)
	
	_update_wave_and_score()


# --- Wall / damage -----------------------------------------------------------

func damage_wall(amount: int) -> void:
	if state == GameState.GAME_OVER:
		return

	wall_health = max(0, wall_health - amount)

	if ui and ui.has_method("update_cave_health"):
		ui.update_cave_health(wall_health, wall_max_health)

	if wall_health <= 0:
		_game_over()


# --- Bird spawning -----------------------------------------------------------

func _spawn_bird() -> void:
	if bird_scene == null or sky_layer == null:
		return

	var bird := bird_scene.instantiate()
	if bird == null:
		return

	sky_layer.add_child(bird)

	var viewport_width := get_viewport_rect().size.x
	var from_left := randf() < 0.5

	var spawn_x := -100.0
	var dir := Vector2.RIGHT

	if not from_left:
		spawn_x = viewport_width + 100.0
		dir = Vector2.LEFT

	var spawn_pos := Vector2(spawn_x, bird_spawn_y)

	if bird.has_method("setup"):
		bird.setup(spawn_pos, dir)
	else:
		bird.global_position = spawn_pos
		if "direction" in bird:
			bird.direction = dir

	birds_spawned_in_wave += 1
	birds_alive += 1

	if bird.has_signal("died"):
		bird.died.connect(_on_bird_died)


# --- Rocks API (unchanged externally) ---------------------------------------

func can_spend_rocks(amount: int) -> bool:
	if caveman == null:
		return false
	return caveman.stone >= amount


func spend_rocks(amount: int) -> bool:
	if not can_spend_rocks(amount):
		return false

	caveman.stone -= amount
	return true


func add_rocks(amount: int) -> void:
	if caveman == null:
		return
	caveman.stone += amount


# --- HUD & highscore helpers -------------------------------------------------

func _update_wave_and_score() -> void:
	if ui and ui.has_method("update_wave_and_score"):
		ui.update_wave_and_score(current_wave, score)


func _load_highscore() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f:
			highscore = f.get_32()
			f.close()
		else:
			highscore = 0
	else:
		highscore = 0


func _save_highscore() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_32(highscore)
		f.close()


func _game_over() -> void:
	if state == GameState.GAME_OVER:
		return

	state = GameState.GAME_OVER
	print("GAME OVER | final score: %d | wave: %d" % [score, current_wave])

	var new_record := false
	if score > highscore:
		highscore = score
		_save_highscore()
		new_record = true

	# Tell UI to show the game over panel
	if ui and ui.has_method("show_game_over"):
		ui.show_game_over(score, highscore, current_wave, new_record)

	# Pause the world, but UI can still work if its pause_mode is PROCESS
	get_tree().paused = true
