extends Node2D

@export var speed: float = 200.0
@export var interact_radius: float = 16.0

# "Physical" sizes (tweak to taste)
@export var caveman_radius: float = 10.0
@export var tree_radius: float = 26.0
@export var rock_radius: float = 18.0

# World references
var walk_area_top_left: Node2D
var walk_area_bottom_right: Node2D
var tree: Node2D
var rock: Node2D

# Solid objects for simple collision
var solids: Array = []

@onready var anim_player: AnimationPlayer = $AnimationPlayer
var current_anim: String = ""
var base_scale_x: float
var is_chopping: bool = false

# Resources
var wood: int = 0
var stone: int = 0

# Gathering settings
@export var chops_per_wood: int = 3
@export var hits_per_stone: int = 4

var _tree_chop_progress: int = 0
var _rock_hit_progress: int = 0

# Tower building vars
@export var tower_build_radius: float = 34.0


const TOWER_COST_WOOD: int = 5
const TOWER_COST_STONE: int = 2

var tower_spots: Array[Node2D] = []

@onready var tower_scene: PackedScene = preload("res://scenes/world/Tower.tscn")


func _ready() -> void:
	var world := get_tree().current_scene.get_node("World/GroundLayer")
	var walk_area := world.get_node("WalkArea")
	walk_area_top_left = walk_area.get_node("TopLeft")
	walk_area_bottom_right = walk_area.get_node("BottomRight")

	tree = world.get_node("TreeSpot/Tree")
	rock = world.get_node("RockSpot/Rock")
	
	if tree and tree.has_method("setup"):
		tree.setup(chops_per_wood)

	if rock and rock.has_method("setup"):
		rock.setup(hits_per_stone)
	
	for spot in get_tree().get_nodes_in_group("tower_spot"):
		if spot is Node2D:
			tower_spots.append(spot)
	print("[Caveman] Found tower spots:", tower_spots.size())

	# Define solid obstacles (centre + radius)
	solids = [
		{"node": tree, "radius": tree_radius},
		{"node": rock, "radius": rock_radius},
	]

	base_scale_x = scale.x

	anim_player.animation_finished.connect(_on_animation_finished)
	_play_anim("idle")


func _process(delta: float) -> void:

	var input_vector := Vector2.ZERO

	if Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_right"):
		input_vector.x += 1
	if Input.is_action_pressed("ui_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("ui_down"):
		input_vector.y += 1

	input_vector = input_vector.normalized()

	# --- Movement with soft collision (Node2D style) ---
	var desired_pos := global_position + input_vector * speed * delta
	desired_pos = _resolve_solids(desired_pos)
	desired_pos = _clamp_to_walk_area(desired_pos)
	global_position = desired_pos


	# Flip only based on INTENTIONAL input, and never during chopping
	if not is_chopping:
		if Input.is_action_pressed("ui_right"):
			scale.x = abs(base_scale_x)
		elif Input.is_action_pressed("ui_left"):
			scale.x = -abs(base_scale_x)

	


	# Only change walk/idle if not chopping
	if not is_chopping:
		if input_vector.length() > 0.1:
			_play_anim("walk")
		else:
			_play_anim("idle")

	_update_resource_bars_visibility()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_try_interact()


func _try_interact() -> void:
	if is_chopping:
		return  # busy

	# 1) Try tower building
	if _try_build_tower():
		return

	# 2) Try chopping / mining
	if _try_chop_or_mine():
		return


func _try_build_tower() -> bool:
	if tower_spots.is_empty():
		return false

	var closest_spot: Node2D = null
	var best_dist := INF

	for spot in tower_spots:
		if spot.get_node_or_null("BuiltTower") != null:
			continue

		var marker := spot.get_node_or_null("BuildMarker") as Node2D
		if marker == null:
			continue

		var d := global_position.distance_to(marker.global_position)
		if d < best_dist:
			best_dist = d
			closest_spot = spot

	if closest_spot == null or best_dist > tower_build_radius:
		return false

	if wood < TOWER_COST_WOOD or stone < TOWER_COST_STONE:
		print("[Caveman] Not enough to build tower.")
		return false

	wood -= TOWER_COST_WOOD
	stone -= TOWER_COST_STONE
	print("[Caveman] Built tower! Wood:", wood, " Stone:", stone)

	var tower := tower_scene.instantiate()
	tower.name = "BuiltTower"
	closest_spot.add_child(tower)
	tower.position = Vector2.ZERO

	return true

func _try_chop_or_mine() -> bool:
	var did_something := false

	var d_tree := global_position.distance_to(tree.global_position)
	var d_rock := global_position.distance_to(rock.global_position)

	# Prioritise tree if both are somehow in range
	if d_tree <= (tree_radius + caveman_radius + interact_radius):
		is_chopping = true
		anim_player.play("chop")

		_tree_chop_progress += 1
		print("[Caveman] Chopping tree... hit %d / %d" % [_tree_chop_progress, chops_per_wood])

		if tree and tree.has_method("update_progress"):
			tree.update_progress(_tree_chop_progress)

		if _tree_chop_progress >= chops_per_wood:
			_tree_chop_progress = 0
			wood += 1
			print("[Caveman] Collected WOOD! Total wood =", wood)

			if tree and tree.has_method("play_collected"):
				tree.play_collected()

		did_something = true

	elif d_rock <= (rock_radius + caveman_radius + interact_radius):
		is_chopping = true
		anim_player.play("chop")

		_rock_hit_progress += 1
		print("[Caveman] Mining rock... hit %d / %d" % [_rock_hit_progress, hits_per_stone])

		if rock and rock.has_method("update_progress"):
			rock.update_progress(_rock_hit_progress)

		if _rock_hit_progress >= hits_per_stone:
			_rock_hit_progress = 0
			stone += 1
			print("[Caveman] Collected STONE! Total stone =", stone)

			if rock and rock.has_method("play_collected"):
				rock.play_collected()

		did_something = true

	return did_something




func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "chop":
		is_chopping = false



func _clamp_to_walk_area(pos: Vector2) -> Vector2:
	var min_x := walk_area_top_left.global_position.x
	var min_y := walk_area_top_left.global_position.y
	var max_x := walk_area_bottom_right.global_position.x
	var max_y := walk_area_bottom_right.global_position.y

	pos.x = clamp(pos.x, min_x, max_x)
	pos.y = clamp(pos.y, min_y, max_y)
	return pos


func _resolve_solids(desired_pos: Vector2) -> Vector2:
	var pos := desired_pos

	for solid in solids:
		var node: Node2D = solid["node"]
		if node == null or not node.is_inside_tree():
			continue

		var radius: float = solid["radius"]
		var centre := node.global_position
		var offset := pos - centre
		var min_dist := radius + caveman_radius
		var dist := offset.length()

		if dist < min_dist and dist > 0.001:
			offset = offset.normalized() * min_dist
			pos = centre + offset

	return pos

func _update_resource_bars_visibility() -> void:
	# Hide tree bar if too far away
	if tree and tree.has_method("clear_progress"):
		var d_tree := global_position.distance_to(tree.global_position)
		if d_tree > (tree_radius + caveman_radius + interact_radius):
			tree.clear_progress()

	# Hide rock bar if too far away
	if rock and rock.has_method("clear_progress"):
		var d_rock := global_position.distance_to(rock.global_position)
		if d_rock > (rock_radius + caveman_radius + interact_radius):
			rock.clear_progress()



func _play_anim(name: String) -> void:
	if current_anim == name:
		return
	current_anim = name
	anim_player.play(name)
