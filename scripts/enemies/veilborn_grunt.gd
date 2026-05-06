extends CharacterBody2D

@export var max_hp: int = 3
@export var contact_damage: int = 1
@export var damage_cooldown: float = 1.0

@onready var damage_area: Area2D = $DamageArea

var current_hp: int
var can_damage_player: bool = true

func _ready() -> void:
	current_hp = max_hp
	print(name, " ready with HP: ", current_hp)

func _physics_process(delta: float) -> void:
	check_player_contact_damage()

func check_player_contact_damage() -> void:
	if not can_damage_player:
		return

	var bodies := damage_area.get_overlapping_bodies()

	for body in bodies:
		# Important:
		# Do not damage self or other enemies.
		# Only damage something that is specifically the player.
		if body == self:
			continue

		if body.name == "Player" and body.has_method("take_damage"):
			body.take_damage(contact_damage)
			start_damage_cooldown()
			break

func start_damage_cooldown() -> void:
	can_damage_player = false
	await get_tree().create_timer(damage_cooldown).timeout
	can_damage_player = true

func take_damage(amount: int) -> void:
	current_hp -= amount
	print(name, " took ", amount, " damage. HP left: ", current_hp)

	if current_hp <= 0:
		die()

func die() -> void:
	print(name, " defeated")
	queue_free()
