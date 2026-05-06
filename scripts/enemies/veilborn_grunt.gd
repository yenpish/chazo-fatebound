extends CharacterBody2D

@export var max_hp: int = 3

var current_hp: int

func _ready() -> void:
	current_hp = max_hp
	print(name, " ready with HP: ", current_hp)

func take_damage(amount: int) -> void:
	current_hp -= amount
	print(name, " took ", amount, " damage. HP left: ", current_hp)

	if current_hp <= 0:
		die()

func die() -> void:
	print(name, " defeated")
	queue_free()
