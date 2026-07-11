extends "res://scenes/world/bird.gd"

@export var explosion_radius := 140.0
@export var explosion_damage := 3
@export var explosion_scene: PackedScene  # assign BigExplosion.tscn

func take_damage(amount):
	health -= amount
	if health <= 0:
		_explode()
		died.emit()
		queue_free()

func _explode():
	if explosion_scene:
		var boom = explosion_scene.instantiate()
		boom.global_position = global_position
		get_tree().current_scene.add_child(boom)

	# Damage nearby enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e == self:
			continue
		var dist = global_position.distance_to(e.global_position)
		if dist <= explosion_radius:
			if e.has_method("take_damage"):
				e.take_damage(explosion_damage)
