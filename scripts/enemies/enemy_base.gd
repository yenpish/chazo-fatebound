extends CharacterBody2D

# === Enemy Stats ===
@export var max_hp: int = 3
@export var move_speed: float = 90.0
@export var contact_damage: int = 1
@export var damage_cooldown: float = 1.0
@export var chase_range: float = 600.0
@export var stop_distance: float = 35.0

# === Node References ===
@onready var damage_area: Area2D = $DamageArea
@onready var placeholder_sprite: Sprite2D = $PlaceholderSprite

# === State Variables ===
var current_hp: int
var can_damage_player: bool = true
var is_dead: bool = false
var player: Node2D = null
var original_sprite_modulate: Color

# === Hitstop / knockback ===
var is_hitstopped: bool = false
var hitstop_timer: float = 0.0

# === Debug ===
var debug_label: Label = null

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	current_hp = max_hp

	if placeholder_sprite != null:
		original_sprite_modulate = placeholder_sprite.modulate

	find_player()
	setup_debug_label()
	print(name, " ready with HP: ", current_hp)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Hitstop handling
	if is_hitstopped:
		hitstop_timer -= delta
		if hitstop_timer <= 0:
			is_hitstopped = false
		move_and_slide()
		return

	if player == null:
		find_player()

	chase_player()
	check_player_contact_damage()
	update_debug_label()
	move_and_slide()

func find_player() -> void:
	player = get_tree().get_first_node_in_group("player") as Node2D

func chase_player() -> void:
	if player == null:
		velocity = Vector2.ZERO
		return

	var direction_to_player := player.global_position - global_position
	var distance_to_player := direction_to_player.length()

	if distance_to_player <= chase_range and distance_to_player > stop_distance:
		velocity = direction_to_player.normalized() * move_speed
	else:
		velocity = Vector2.ZERO

func check_player_contact_damage() -> void:
	if not can_damage_player or damage_area == null:
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

# === Damage, hitstop, knockback, flash ===
func take_damage(amount: int) -> void:
	if is_dead:
		return

	current_hp -= amount
	current_hp = max(current_hp, 0)
	print(name, " took ", amount, " damage. HP left: ", current_hp)

	flash_hit()

	# Only apply hitstop and knockback for non-boss enemies
	if not is_in_group("boss"):
		is_hitstopped = true
		hitstop_timer = 0.12
		if player != null:
			var dir = (global_position - player.global_position).normalized()
			velocity = dir * 200  # visible knockback

	if current_hp <= 0:
		die()

func flash_hit() -> void:
	if placeholder_sprite == null:
		return
	placeholder_sprite.modulate = Color(2, 2, 2, 1)
	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(placeholder_sprite):
		placeholder_sprite.modulate = original_sprite_modulate

# === Debug Label ===
func setup_debug_label() -> void:
	debug_label = Label.new()
	debug_label.visible = false
	debug_label.position = Vector2(-20, -50)
	debug_label.scale = Vector2(0.7, 0.7)
	add_child(debug_label)

func update_debug_label() -> void:
	if debug_label == null:
		return

	var debug_manager = get_tree().get_first_node_in_group("debug_manager")
	if debug_manager == null:
		debug_label.visible = false
		return

	if debug_manager.debug_enabled:
		debug_label.visible = true
		debug_label.text = "HP: " + str(current_hp)
	else:
		debug_label.visible = false

# === Death ===
func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	print(name, " defeated")
	queue_free()
