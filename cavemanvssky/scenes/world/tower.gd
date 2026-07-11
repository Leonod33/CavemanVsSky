extends Node2D

@export var fire_interval: float = 1.0        # Seconds between shots
@export var range: float = 400.0              # How far the tower can see
@export var projectile_scene: PackedScene     # Assign Rock.tscn in the inspector

var _cooldown: float = 0.0

var caveman: Node = null

func _ready() -> void:
		# Try to find the caveman once at startup
	caveman = get_tree().get_first_node_in_group("caveman")
	# Start with a random offset so multiple towers don't all fire in sync
	_cooldown = randf_range(0.0, fire_interval)


func _process(delta: float) -> void:
	if projectile_scene == null:
		return

	var fire_rate_mult := 1.0
	if caveman and caveman.has_method("get_tower_fire_rate_multiplier"):
		fire_rate_mult = caveman.get_tower_fire_rate_multiplier()

	# Higher multiplier = cooldown ticks down faster
	_cooldown -= delta * fire_rate_mult
	if _cooldown > 0.0:
		return


	var target := _find_target()
	if target == null:
		# No enemies in range – don't reset cooldown so we keep checking every frame
		return

	_cooldown = fire_interval
	_shoot_at(target)


func _find_target() -> Node2D:
	# This will start working as soon as we have enemies that call add_to_group("enemies")
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null

	var best: Node2D = null
	var best_dist_sq := range * range

	for e in enemies:
		if not (e is Node2D):
			continue

		var dist_sq := global_position.distance_squared_to(e.global_position)
		if dist_sq <= best_dist_sq:
			best_dist_sq = dist_sq
			best = e

	return best


func _shoot_at(target: Node2D) -> void:
	var rock := projectile_scene.instantiate()
	if rock == null:
		return

	# Put the rock in the same layer as the tower so it appears in the world
	get_parent().add_child(rock)
	rock.global_position = global_position

	var dir := (target.global_position - global_position).normalized()

	# --- Apply tower damage multiplier, if available ---
	var dmg_mult := 1.0
	if caveman and caveman.has_method("get_tower_damage_multiplier"):
		dmg_mult = caveman.get_tower_damage_multiplier()

	if rock.has_method("set_damage_multiplier"):
		rock.set_damage_multiplier(dmg_mult)
	else:
		# absolute fallback
		if "damage" in rock:
			rock.damage = int(round(rock.damage * dmg_mult))


	# Launch the rock
	if rock.has_method("launch"):
		rock.launch(dir)
		
	elif "direction" in rock:
		rock.direction = dir
