extends Node2D

@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	# Play the explosion anim as soon as the scene spawns
	anim.play("explode")
	_do_screen_shake()

	# Make sure we get notified when the animation finishes
	anim.animation_finished.connect(_on_animation_finished)

func _do_screen_shake() -> void:
	var viewport := get_viewport()
	var original_transform := viewport.canvas_transform

	# Nudge the whole screen a bit to the right (you can randomise this later)
	viewport.canvas_transform = Transform2D(0.0, Vector2(4, 0))

	# After a short delay, reset the transform
	await get_tree().create_timer(0.1).timeout
	viewport.canvas_transform = original_transform


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "explode":
		# This removes the explosion node from the scene tree
		queue_free()
