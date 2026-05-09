extends CharacterBody2D

signal hp_changed(current_hp: int, max_hp: int)
signal player_died

@export var move_speed: float = 180.0
@export var max_hp: int = 5
@export var attack_duration: float = 0.15
@export var attack_damage: int = 1
@export var attack_distance: float = 60.0

@onready var attack_area: Area2D = $AttackArea
@onready var attack_collision: CollisionShape2D = $AttackArea/AttackCollision
@onready var placeholder_sprite: Sprite2D = $PlaceholderSprite

var current_hp: int
var is_attacking: bool = false
var is_dead: bool = false
var last_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("player")
	current_hp = max_hp
	
	# Attack hitbox should be fully inactive until player presses attack.
	attack_collision.disabled = true
	attack_area.monitoring = false
	
	update_attack_area_position()
	hp_changed.emit(current_hp, max_hp)
	print("Player ready with HP: ", current_hp)

func _physics_process(_delta: float) -> void:
	if is_dead:
		handle_restart()
		return

	handle_movement()
	handle_attack()

func handle_movement() -> void:
	var input_direction := Vector2.ZERO

	input_direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_direction.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")

	if input_direction.length() > 0:
		input_direction = input_direction.normalized()
		last_direction = input_direction
		update_attack_area_position()

	velocity = input_direction * move_speed
	move_and_slide()

func update_attack_area_position() -> void:
	if abs(last_direction.x) > abs(last_direction.y):
		if last_direction.x > 0:
			attack_area.position = Vector2(attack_distance, 0)
		else:
			attack_area.position = Vector2(-attack_distance, 0)
	else:
		if last_direction.y > 0:
			attack_area.position = Vector2(0, attack_distance)
		else:
			attack_area.position = Vector2(0, -attack_distance)

func handle_attack() -> void:
	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()
		
func handle_restart() -> void:
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()

func attack() -> void:
	is_attacking = true
	
	# Activate attack area only during attack.
	attack_area.monitoring = true
	attack_collision.disabled = false
	
	print("Player attacked toward: ", last_direction)

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

	flash_hurt()
	if current_hp <= 0:
		die()
		
func flash_hurt() -> void:
	if placeholder_sprite == null:
		return

	placeholder_sprite.modulate = Color(2.0, 2.0, 2.0)
	await get_tree().create_timer(0.08).timeout

	if is_dead:
		return

	placeholder_sprite.modulate = Color(1, 1, 1)

func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	
	player_died.emit()
	
	print("Player defeated / Game Over")
	print("Press R to restart")
