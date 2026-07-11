extends "res://scenes/world/bird.gd"

func _ready() -> void:
	# Call parent logic (bird.gd)
	super._ready()

	# Now override what changes
	speed = 200
	health = 3
