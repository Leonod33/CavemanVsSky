extends Node2D

@export var bird_scene: PackedScene
@export var bird_spawn_interval: float = 3.0  # seconds between birds
@export var bird_spawn_y: float = 260.0       # height of the flight path above the wall
@export var wall_max_health: int = 10
var wall_health: int

var _bird_timer: float = 0.0

@export var starting_rocks: int = 10

@onready var sky_layer: Node2D = $World/SkyLayer
@onready var caveman: Node2D = $World/GroundLayer/Caveman
@onready var ui: Control = $UI

func _ready() -> void:
	print("[Caveman vs Sky] Game scene ready")
	_bird_timer = bird_spawn_interval
	wall_health = wall_max_health

	if ui and ui.has_method("update_cave_health"):
		ui.update_cave_health(wall_health, wall_max_health)
		
	# Initialise shared stone/rock resource on the Caveman
	if caveman:
		caveman.stone = starting_rocks
		_update_hud_rocks()




func _process(delta: float) -> void:
	_bird_timer -= delta
	if _bird_timer <= 0.0:
		_bird_timer = bird_spawn_interval
		_spawn_bird()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Go back to title screen
		get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")

func damage_wall(amount: int) -> void:
	wall_health = max(0, wall_health - amount)

	if ui and ui.has_method("update_cave_health"):
		ui.update_cave_health(wall_health, wall_max_health)

	if wall_health <= 0:
		_game_over()




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

	# Prefer the setup() method if present
	if bird.has_method("setup"):
		bird.setup(spawn_pos, dir)
	else:
		bird.global_position = spawn_pos
		if "direction" in bird:
			bird.direction = dir

			
			
func can_spend_rocks(amount: int) -> bool:
	if caveman == null:
		return false
	return caveman.stone >= amount


func spend_rocks(amount: int) -> bool:
	if not can_spend_rocks(amount):
		return false

	caveman.stone -= amount
	_update_hud_rocks()
	return true


func add_rocks(amount: int) -> void:
	if caveman == null:
		return

	caveman.stone += amount
	_update_hud_rocks()


func _update_hud_rocks() -> void:
	if caveman == null:
		return

	print("Rocks:", caveman.stone)
	# HUD already reads caveman.stone directly every frame



func _game_over() -> void:
	print("GAME OVER")
	# Later: show UI, change scene, fade out, etc.
	get_tree().paused = true   # simple for now
