extends CharacterBody2D

@export var max_hp: int = 2
@export var move_speed: float = 150.0
@export var contact_damage: int = 1
@export var attack_cooldown: float = 0.8
@export var chase_range: float = 700.0
@export var stop_distance: float = 65.0

@onready var damage_area: Area2D = $DamageArea
@onready var placeholder_sprite: AnimatedSprite2D = $PlaceholderSprite

var player: Node2D = null
var is_attacking := false
var current_hp := 2
var is_dead := false

func _ready() -> void:
	current_hp = max_hp
	find_player()

func _physics_process(_delta: float) -> void:
	if is_dead:
		return

	if player == null:
		find_player()

	if player == null:
		return

	var direction = player.global_position - global_position
	var distance = direction.length()

	if distance <= stop_distance:

		if not is_attacking:
			start_attack()

		velocity = Vector2.ZERO

	else:

		velocity = direction.normalized() * move_speed

		if not is_attacking:
			placeholder_sprite.play("fly")

	move_and_slide()

	if player != null:
		placeholder_sprite.flip_h = player.global_position.x > global_position.x

func start_attack() -> void:

	if is_attacking:
		return

	is_attacking = true

	if randi() % 2 == 0:
		placeholder_sprite.play("attack1")
	else:
		placeholder_sprite.play("attack2")

	await get_tree().create_timer(0.3).timeout

	if player != null and player.has_method("take_damage"):
		player.take_damage(contact_damage)

	await get_tree().create_timer(attack_cooldown).timeout

	is_attacking = false

func find_player() -> void:
	player = get_tree().get_first_node_in_group("player") as Node2D

func take_damage(amount: int) -> void:

	current_hp -= amount

	if current_hp <= 0:
		die()

func die() -> void:

	is_dead = true

	if placeholder_sprite.sprite_frames.has_animation("die"):
		placeholder_sprite.play("die")

	await get_tree().create_timer(0.6).timeout

	queue_free()
