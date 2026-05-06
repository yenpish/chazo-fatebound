extends CharacterBody2D

signal hp_changed(current_hp: int, max_hp: int)

@export var move_speed: float = 180.0
@export var max_hp: int = 5
@export var attack_duration: float = 0.15
@export var attack_damage: int = 1

@onready var attack_area: Area2D = $AttackArea
@onready var attack_collision: CollisionShape2D = $AttackArea/AttackCollision

var current_hp: int
var is_attacking: bool = false
var is_dead: bool = false

func _ready() -> void:
	current_hp = max_hp
	
	# Attack hitbox should be fully inactive until player presses attack.
	attack_collision.disabled = true
	attack_area.monitoring = false
	
	hp_changed.emit(current_hp, max_hp)
	print("Player ready with HP: ", current_hp)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	handle_movement()
	handle_attack()

func handle_movement() -> void:
	var input_direction := Vector2.ZERO

	input_direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_direction.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")

	if input_direction.length() > 0:
		input_direction = input_direction.normalized()

	velocity = input_direction * move_speed
	move_and_slide()

func handle_attack() -> void:
	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()

func attack() -> void:
	is_attacking = true
	
	# Activate attack area only during attack.
	attack_area.monitoring = true
	attack_collision.disabled = false
	
	print("Player attacked")

	await get_tree().physics_frame

	var hit_bodies := attack_area.get_overlapping_bodies()

	for body in hit_bodies:
		if body.has_method("take_damage"):
			body.take_damage(attack_damage)

	await get_tree().create_timer(attack_duration).timeout

	# Turn attack area fully off again.
	attack_collision.disabled = true
	attack_area.monitoring = false
	
	is_attacking = false

func take_damage(amount: int) -> void:
	if is_dead:
		return

	current_hp -= amount
	current_hp = max(current_hp, 0)
	
	hp_changed.emit(current_hp, max_hp)
	print("Player took ", amount, " damage. HP left: ", current_hp)

	if current_hp <= 0:
		die()

func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	print("Player defeated / Game Over")
