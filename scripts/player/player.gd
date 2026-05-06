extends CharacterBody2D

@export var move_speed: float = 180.0
@export var attack_duration: float = 0.15
@export var attack_damage: int = 1

@onready var attack_area: Area2D = $AttackArea
@onready var attack_collision: CollisionShape2D = $AttackArea/AttackCollision

var is_attacking: bool = false

func _physics_process(delta: float) -> void:
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
	attack_collision.disabled = false
	print("Player attacked")

	# Wait one physics frame so Godot updates overlap detection
	await get_tree().physics_frame

	var hit_bodies := attack_area.get_overlapping_bodies()

	for body in hit_bodies:
		if body.has_method("take_damage"):
			body.take_damage(attack_damage)

	await get_tree().create_timer(attack_duration).timeout

	attack_collision.disabled = true
	is_attacking = false
