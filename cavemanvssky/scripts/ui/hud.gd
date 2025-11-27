extends Control

@onready var cave_health_bar = $HUDPanel/CaveHealthBar
@onready var wood_label = $HUDPanel/ResourceBar/WoodLabel
@onready var stone_label = $HUDPanel/ResourceBar/StoneLabel

var caveman: Node = null

func _ready() -> void:
	# Find the caveman in the world
	var world := get_tree().current_scene.get_node("World/GroundLayer")
	caveman = world.get_node("Caveman")

	_update_labels()  # show initial values


func _process(_delta: float) -> void:
	if caveman == null:
		return

	_update_labels()


func _update_labels() -> void:
	# Just the numbers now – icons will show what is what
	wood_label.text = str(caveman.wood)
	stone_label.text = str(caveman.stone)


func update_cave_health(current: int, max_health: int) -> void:
	if cave_health_bar == null:
		return

	cave_health_bar.max_value = max_health
	cave_health_bar.value = current
