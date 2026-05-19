extends "res://scripts/enemies/enemy_base.gd"


func _ready() -> void:
	max_hp = 2
	move_speed = 130.0
	contact_damage = 1
	damage_cooldown = 0.8
	chase_range = 700.0
	stop_distance = 25.0

	super()
