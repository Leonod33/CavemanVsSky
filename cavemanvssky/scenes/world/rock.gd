extends Node2D

@export var speed: float = 500.0          # Units per second
@export var max_distance: float = 10000.0   # How far the rock can travel
@export var damage: int = 1               # Damage dealt to enemies
@export var ignore_time: float = 0.06     # Seconds to ignore collisions right after spawn

@onready var hit_area: Area2D = $InteractionArea

var _velocity: Vector2 = Vector2.ZERO
var _start_position: Vector2
var _age: float = 0.0

@onready var work_bar: ProgressBar = $WorkBar
@onready var anim_player: AnimationPlayer = $AnimationPlayer

var _max_hits: int = 1



func _ready() -> void:
	_start_position = global_position
	_age = 0.0

	if hit_area:
		hit_area.body_entered.connect(_on_body_entered)
		hit_area.area_entered.connect(_on_area_entered)




func launch(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return

	_velocity = direction.normalized() * speed



func _process(delta: float) -> void:
	_age += delta

	if _velocity == Vector2.ZERO:
		return

	global_position += _velocity * delta


	# Only start checking distance after a tiny bit of time to avoid any weird zero-frame issues
	if _age > 0.02:
		var dist_sq := global_position.distance_squared_to(_start_position)
		if dist_sq > max_distance * max_distance:

			queue_free()


func _handle_hit(target: Node) -> void:
	# Ignore collisions in the first few frames so we don't insta-hit things we spawn inside
	if _age < ignore_time:

		return

	if target == null:
		return

	var enemy := target

	# If we hit a child (like HitArea), check its parent too
	if not enemy.is_in_group("enemies") and enemy.get_parent():
		if enemy.get_parent().is_in_group("enemies"):
			enemy = enemy.get_parent()



	if enemy.is_in_group("enemies"):
		if enemy.has_method("take_damage"):

			enemy.take_damage(damage)


		queue_free()


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

func _on_body_entered(body: Node) -> void:
	_handle_hit(body)


func _on_area_entered(area: Area2D) -> void:
	_handle_hit(area)
