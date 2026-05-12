extends CharacterBody2D

signal hp_changed(current_hp: int, max_hp: int)
signal player_died

@export var move_speed: float = 180.0
@export var max_hp: int = 5
@export var attack_duration: float = 0.15
@export var attack_damage: int = 1

@export var attack_gap: float = 2.0
@export var horizontal_attack_size: Vector2 = Vector2(55, 34)
@export var vertical_attack_size: Vector2 = Vector2(34, 55)

@onready var attack_area: Area2D = $AttackArea
@onready var attack_collision: CollisionShape2D = $AttackArea/AttackCollision
@onready var placeholder_sprite: Sprite2D = $PlaceholderSprite
@onready var body_collision: CollisionShape2D = $CollisionShape2D

const CHAZO_DOWN_TEXTURE: Texture2D = preload("res://assets/sprites/chazo-down.png")
const CHAZO_RIGHT_TEXTURE: Texture2D = preload("res://assets/sprites/chazo-right.png")
const CHAZO_LEFT_TEXTURE: Texture2D = preload("res://assets/sprites/chazo-left.png")
const CHAZO_UP_TEXTURE: Texture2D = preload("res://assets/sprites/chazo-up.png")

var current_hp: int
var is_attacking: bool = false
var is_dead: bool = false
var last_direction: Vector2 = Vector2.DOWN


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("player")
	current_hp = max_hp
	
	# Attack hitbox should be fully inactive until player presses attack.
	attack_collision.disabled = true
	attack_area.monitoring = false
	
	# The script controls AttackArea position.
	# AttackCollision should stay centered inside AttackArea.
	attack_collision.position = Vector2.ZERO
	
	update_player_sprite_direction()
	update_attack_area_position()

	# Wait one frame so HUD and its child nodes are fully ready.
	await get_tree().process_frame
	
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
		last_direction = get_cardinal_direction(input_direction)
		update_player_sprite_direction()
		update_attack_area_position()

	velocity = input_direction * move_speed
	move_and_slide()


func get_cardinal_direction(direction: Vector2) -> Vector2:
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			return Vector2.RIGHT
		else:
			return Vector2.LEFT
	else:
		if direction.y > 0:
			return Vector2.DOWN
		else:
			return Vector2.UP

func update_player_sprite_direction() -> void:
	if placeholder_sprite == null:
		return

	if last_direction == Vector2.RIGHT:
		placeholder_sprite.texture = CHAZO_RIGHT_TEXTURE

	elif last_direction == Vector2.LEFT:
		placeholder_sprite.texture = CHAZO_LEFT_TEXTURE

	elif last_direction == Vector2.UP:
		placeholder_sprite.texture = CHAZO_UP_TEXTURE

	elif last_direction == Vector2.DOWN:
		placeholder_sprite.texture = CHAZO_DOWN_TEXTURE

func update_attack_area_position() -> void:
	var attack_shape := attack_collision.shape as RectangleShape2D
	var body_shape := body_collision.shape as RectangleShape2D

	if attack_shape == null:
		print("AttackCollision shape is not RectangleShape2D.")
		return

	if body_shape == null:
		print("Player CollisionShape2D shape is not RectangleShape2D.")
		return

	attack_collision.position = Vector2.ZERO

	var body_center: Vector2 = body_collision.position
	var body_half_size: Vector2 = body_shape.size * 0.5

	if last_direction == Vector2.RIGHT:
		attack_shape.size = horizontal_attack_size
		var attack_half_size: Vector2 = horizontal_attack_size * 0.5
		attack_area.position = Vector2(
			body_center.x + body_half_size.x + attack_half_size.x + attack_gap,
			body_center.y
		)

	elif last_direction == Vector2.LEFT:
		attack_shape.size = horizontal_attack_size
		var attack_half_size: Vector2 = horizontal_attack_size * 0.5
		attack_area.position = Vector2(
			body_center.x - body_half_size.x - attack_half_size.x - attack_gap,
			body_center.y
		)

	elif last_direction == Vector2.UP:
		attack_shape.size = vertical_attack_size
		var attack_half_size: Vector2 = vertical_attack_size * 0.5
		attack_area.position = Vector2(
			body_center.x,
			body_center.y - body_half_size.y - attack_half_size.y - attack_gap
		)

	elif last_direction == Vector2.DOWN:
		attack_shape.size = vertical_attack_size
		var attack_half_size: Vector2 = vertical_attack_size * 0.5
		attack_area.position = Vector2(
			body_center.x,
			body_center.y + body_half_size.y + attack_half_size.y + attack_gap
		)

func handle_attack() -> void:
	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()
		

func handle_restart() -> void:
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()


func attack() -> void:
	is_attacking = true
	
	# Make sure the hitbox is correct at the exact moment of attack.
	update_attack_area_position()
	
	# Activate attack area only during attack.
	attack_area.monitoring = true
	attack_collision.disabled = false
	
	print("Player attacked toward: ", last_direction)

	await get_tree().physics_frame

	var hit_bodies := attack_area.get_overlapping_bodies()

	for body in hit_bodies:
		if body == self:
			continue

		if body.is_in_group("player"):
			continue

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
