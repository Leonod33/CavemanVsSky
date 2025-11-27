extends Node2D

@export var speed: float = 130.0
@export var health: int = 5
@export var screen_margin: float = 200.0
@export var attack_interval: float = 1.0      # seconds between pecks
@export var pass_drop: float = 75.0           # how much lower each new pass is
@export var land_offset_y: float = -40.0      # how high above the cave entrance to sit

var _direction: Vector2 = Vector2.RIGHT
var pass_number: int = 1

var is_landing: bool = false
var is_attacking: bool = false
var _attack_timer: float = 0.0
var _land_target_pos: Vector2

@onready var anim_player: AnimationPlayer = $AnimationPlayer
var _cave: Node2D = null

signal died


func _ready() -> void:
	add_to_group("enemies")

	if anim_player:
		anim_player.play("flapping")

	# Find the cave entrance so we know where to land
	var game := get_tree().current_scene
	if game and game.has_node("World/WallLayer/CaveEntrance"):
		_cave = game.get_node("World/WallLayer/CaveEntrance")

	_update_facing()


func setup(start_pos: Vector2, move_dir: Vector2) -> void:
	global_position = start_pos
	if move_dir != Vector2.ZERO:
		_direction = move_dir.normalized()
	_update_facing()


func _process(delta: float) -> void:
	if is_attacking:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_attack_timer = attack_interval
			peck_wall()
		return

	if is_landing:
		_process_landing(delta)
		return

	# --- Normal flying ---
	global_position += _direction * speed * delta

	# On the 3rd pass, if we reach the cave horizontally, start landing
	if pass_number >= 3 and _cave:
		var cave_x := _cave.global_position.x
		if (_direction.x > 0.0 and global_position.x >= cave_x) \
		or (_direction.x < 0.0 and global_position.x <= cave_x):
			_start_landing()
			return

	# Handle going off-screen for pass transitions (only while flying)
	var viewport_width := get_viewport_rect().size.x
	if global_position.x < -screen_margin or global_position.x > viewport_width + screen_margin:
		_handle_pass_complete()


func _handle_pass_complete() -> void:
	pass_number += 1

	if pass_number == 2 or pass_number == 3:
		# New pass: reverse direction and fly lower
		_direction.x = -_direction.x
		_update_facing()
		global_position.y += pass_drop
	# No more passes after 3; on pass 3 we land when over the cave


func _start_landing() -> void:
	if not _cave:
		# Fallback: just land in the middle-top area
		var view := get_viewport_rect()
		_land_target_pos = Vector2(view.size.x / 2.0, view.size.y * 0.35)
	else:
		# Snap horizontally above the cave, then we will descend
		_land_target_pos = _cave.global_position + Vector2(0, land_offset_y)
		global_position.x = _cave.global_position.x

	is_landing = true
	_direction = Vector2.ZERO   # stop horizontal motion


func _process_landing(delta: float) -> void:
	# Move straight toward the land target (mostly vertical)
	var descend_speed := 120.0
	var to_target := _land_target_pos - global_position
	var dist := to_target.length()

	if dist <= descend_speed * delta:
		global_position = _land_target_pos
		is_landing = false
		_begin_attack()
	else:
		global_position += to_target.normalized() * descend_speed * delta


func _begin_attack() -> void:
	is_attacking = true
	_attack_timer = attack_interval


func peck_wall() -> void:
	var game := get_tree().current_scene
	if game and game.has_method("damage_wall"):
		game.damage_wall(1)


func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		died.emit()
		queue_free()


func _update_facing() -> void:
	if _direction.x > 0.0:
		scale.x = abs(scale.x)        # face right
	elif _direction.x < 0.0:
		scale.x = -abs(scale.x)       # face left
	# If direction is zero (landed/landing), keep current facing
