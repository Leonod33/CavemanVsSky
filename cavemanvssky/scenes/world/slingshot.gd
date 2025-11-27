extends Node2D

@export var projectile_scene: PackedScene      # set to your RockProjectile.tscn
@export var fire_cooldown: float = 0.35
@export var rock_cost: int = 1
@export var slingshot_damage: int = 3          # stronger than normal tower rocks
@export var slingshot_speed: float = 800.0     # faster than tower shots

@onready var interaction_area: Area2D = $InteractionArea

var _player_in_range: bool = false
var _cooldown: float = 0.0

func _ready() -> void:
	if interaction_area:
		interaction_area.area_entered.connect(_on_area_entered)
		interaction_area.area_exited.connect(_on_area_exited)


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta

	if not _player_in_range:
		return

	# Manual control: press the fire button while standing at the slingshot
	if Input.is_action_just_pressed("slingshot_fire"):
		_try_fire()


func _on_body_entered(body: Node) -> void:
	# You can tighten this later (e.g. check a "player" group)
	if body.name == "Caveman":
		_player_in_range = true


func _on_body_exited(body: Node) -> void:
	if body.name == "Caveman":
		_player_in_range = false


func _on_area_entered(area: Area2D) -> void:
	# We assume the caveman has an Area2D child called "InteractArea"
	var owner := area.get_owner()
	if owner and owner.name == "Caveman":
		_player_in_range = true


func _on_area_exited(area: Area2D) -> void:
	var owner := area.get_owner()
	if owner and owner.name == "Caveman":
		_player_in_range = false


func _try_fire() -> void:
	if _cooldown > 0.0:
		return

	if projectile_scene == null:
		print("No projectile scene assigned!")
		return

	var game := get_tree().current_scene
	if game and game.has_method("spend_rocks"):
		if not game.spend_rocks(rock_cost):
			print("Not enough rocks!")
			return

	# Cooldown starts now
	_cooldown = fire_cooldown

	# Spawn projectile
	var proj := projectile_scene.instantiate()
	if proj == null:
		print("Failed to instantiate projectile")
		return

	# Add to SkyLayer so it's visible
	var sky := game.get_node("World/SkyLayer")
	sky.add_child(proj)
	



	# Spawn it slightly above the slingshot so it doesn't collide immediately
	proj.global_position = global_position + Vector2(0, -130)

	# Set special slingshot stats
	if "damage" in proj:
		proj.damage = slingshot_damage
	if "speed" in proj:
		proj.speed = slingshot_speed

	# Launch straight up
	if proj.has_method("launch"):
		proj.launch(Vector2.UP)
		print("Projectile spawned at:", proj.global_position, " z_index:", proj.z_index)
	else:
		print("Projectile has no launch() method!")

		
