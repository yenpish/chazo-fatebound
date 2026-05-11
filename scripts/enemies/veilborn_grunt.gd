extends CharacterBody2D

@export var max_hp: int = 3
@export var move_speed: float = 90.0
@export var contact_damage: int = 1
@export var damage_cooldown: float = 1.0
@export var chase_range: float = 600.0
@export var stop_distance: float = 35.0

@onready var damage_area: Area2D = $DamageArea
@onready var placeholder_sprite: Sprite2D = $PlaceholderSprite

var current_hp: int
var can_damage_player: bool = true
var player: Node2D = null
var is_dead: bool = false
var original_sprite_modulate: Color

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	current_hp = max_hp
	original_sprite_modulate = placeholder_sprite.modulate
	find_player()
	print(name, " ready with HP: ", current_hp)

func _physics_process(_delta: float) -> void:
	if is_dead:
		return

	if player == null:
		find_player()

	chase_player()
	check_player_contact_damage()

func find_player() -> void:
	player = get_tree().get_first_node_in_group("player") as Node2D

func chase_player() -> void:
	if player == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction_to_player := player.global_position - global_position
	var distance_to_player := direction_to_player.length()

	if distance_to_player <= chase_range and distance_to_player > stop_distance:
		velocity = direction_to_player.normalized() * move_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func is_touching_player() -> bool:
	var bodies := damage_area.get_overlapping_bodies()

	for body in bodies:
		if body.is_in_group("player"):
			return true

	return false

func check_player_contact_damage() -> void:
	if not can_damage_player:
		return

	var bodies := damage_area.get_overlapping_bodies()

	for body in bodies:
		if body == self:
			continue

		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(contact_damage)
			start_damage_cooldown()
			break

func start_damage_cooldown() -> void:
	can_damage_player = false
	await get_tree().create_timer(damage_cooldown).timeout
	can_damage_player = true

func take_damage(amount: int) -> void:
	if is_dead:
		return

	current_hp -= amount
	print(name, " took ", amount, " damage. HP left: ", current_hp)

	flash_hit()

	if current_hp <= 0:
		die()

func flash_hit() -> void:
	if placeholder_sprite == null:
		return

	placeholder_sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
	await get_tree().create_timer(0.08).timeout

	if is_dead:
		return

	if is_instance_valid(placeholder_sprite):
		placeholder_sprite.modulate = original_sprite_modulate

func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	print(name, " defeated")
	queue_free()
