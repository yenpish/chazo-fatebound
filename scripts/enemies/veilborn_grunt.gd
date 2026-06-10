extends "res://scripts/enemies/enemy_base.gd"

func _ready() -> void:
	max_hp = 3
	move_speed = 90.0
	contact_damage = 1
	damage_cooldown = 1.0
	chase_range = 600.0
	stop_distance = 65.0

	super()
