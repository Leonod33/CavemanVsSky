extends Node2D
class_name BaseEnemy

@export var speed: float = 150.0
@export var health: int = 5

signal died

func _ready() -> void:
	add_to_group("enemies")

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		died.emit()
		queue_free()
