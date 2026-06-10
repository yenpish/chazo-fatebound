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
@export var invulnerability_duration: float = 0.5

@onready var attack_area: Area2D = $AttackArea
@onready var attack_collision: CollisionShape2D = $AttackArea/AttackCollision
@onready var placeholder_sprite: Sprite2D = $PlaceholderSprite
@onready var body_collision: CollisionShape2D = $CollisionShape2D

const CHAZO_DOWN_TEXTURE: Texture2D = preload("res://assets/sprites/front.png")
const CHAZO_RIGHT_TEXTURE: Texture2D = preload("res://assets/sprites/right.png")
const CHAZO_LEFT_TEXTURE: Texture2D = preload("res://assets/sprites/left.png")
const CHAZO_UP_TEXTURE: Texture2D = preload("res://assets/sprites/back.png")

var current_hp: int
var is_attacking: bool = false
var is_dead: bool = false
var last_direction: Vector2 = Vector2.DOWN

# === Hitstop / Invulnerability ===
var is_hitstopped: bool = false
var hitstop_timer: float = 0.0
var is_invulnerable: bool = false

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("player")
	current_hp = clamp(DemoState.player_hp, 0, max_hp)
	
	attack_collision.disabled = true
	attack_area.monitoring = false
	attack_collision.position = Vector2.ZERO
	
	update_player_sprite_direction()
	update_attack_area_position()
	await get_tree().process_frame
	
	hp_changed.emit(current_hp, max_hp)
	print("Player ready with HP: ", current_hp)

func _physics_process(_delta: float) -> void:
	if is_dead:
		handle_restart()
		return

	# Hitstop handling
	if is_hitstopped:
		hitstop_timer -= _delta
		if hitstop_timer <= 0:
			is_hitstopped = false
		move_and_slide()
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
		return Vector2.RIGHT if direction.x > 0 else Vector2.LEFT
	else:
		return Vector2.DOWN if direction.y > 0 else Vector2.UP

func update_player_sprite_direction() -> void:
	if placeholder_sprite == null:
		return

	match last_direction:
		Vector2.RIGHT:
			placeholder_sprite.texture = CHAZO_RIGHT_TEXTURE
		Vector2.LEFT:
			placeholder_sprite.texture = CHAZO_LEFT_TEXTURE
		Vector2.UP:
			placeholder_sprite.texture = CHAZO_UP_TEXTURE
		Vector2.DOWN:
			placeholder_sprite.texture = CHAZO_DOWN_TEXTURE

func update_attack_area_position() -> void:
	var attack_shape := attack_collision.shape as RectangleShape2D
	var body_shape := body_collision.shape as RectangleShape2D
	if attack_shape == null or body_shape == null:
		return

	attack_collision.position = Vector2.ZERO
	var body_center = body_collision.position
	var body_half_size = body_shape.size * 0.5

	match last_direction:
		Vector2.RIGHT:
			attack_shape.size = horizontal_attack_size
			attack_area.position = Vector2(body_center.x + body_half_size.x + horizontal_attack_size.x * 0.5 + attack_gap, body_center.y)
		Vector2.LEFT:
			attack_shape.size = horizontal_attack_size
			attack_area.position = Vector2(body_center.x - body_half_size.x - horizontal_attack_size.x * 0.5 - attack_gap, body_center.y)
		Vector2.UP:
			attack_shape.size = vertical_attack_size
			attack_area.position = Vector2(body_center.x, body_center.y - body_half_size.y - vertical_attack_size.y * 0.5 - attack_gap)
		Vector2.DOWN:
			attack_shape.size = vertical_attack_size
			attack_area.position = Vector2(body_center.x, body_center.y + body_half_size.y + vertical_attack_size.y * 0.5 + attack_gap)

func handle_attack() -> void:
	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()

func handle_restart() -> void:
	if Input.is_action_just_pressed("restart"):
		DemoState.reset_demo_state()
		get_tree().change_scene_to_file(
			"res://scenes/tutorial_room.tscn"
		)

func attack() -> void:
	$AttackSFX.play()
	is_attacking = true
	update_attack_area_position()
	attack_area.monitoring = true
	attack_collision.disabled = false
	
	print("Player attacked toward: ", last_direction)
	await get_tree().physics_frame

	for area in attack_area.get_overlapping_areas():

		if area.name != "Hurtbox":
			continue

		var target = area.get_parent()

		if target == self:
			continue

		if target.has_method("take_damage"):
			target.take_damage(attack_damage)
			trigger_hitstop(0.05)

	await get_tree().create_timer(attack_duration).timeout
	attack_collision.disabled = true
	attack_area.monitoring = false
	is_attacking = false

func take_damage(amount: int) -> void:
	if is_dead or is_invulnerable:
		return

	$HurtSFX.play()

	current_hp -= amount
	current_hp = max(current_hp, 0)
	
	DemoState.player_hp = current_hp
	
	hp_changed.emit(current_hp, max_hp)
	print("Player took ", amount, " damage. HP left: ", current_hp)

	flash_hurt()
	trigger_invulnerability(invulnerability_duration)
	if current_hp <= 0:
		die()

func flash_hurt() -> void:
	if placeholder_sprite == null:
		return
	placeholder_sprite.modulate = Color(2, 2, 2)
	await get_tree().create_timer(0.08).timeout
	if is_dead:
		return
	placeholder_sprite.modulate = Color(1, 1, 1)

func trigger_hitstop(duration: float) -> void:
	is_hitstopped = true
	hitstop_timer = duration

func trigger_invulnerability(duration: float) -> void:
	is_invulnerable = true
	await get_tree().create_timer(duration).timeout
	is_invulnerable = false

func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	player_died.emit()
	print("Player defeated / Game Over")
	print("Press R to restart")


func _on_exit_trigger_body_entered(body: Node2D) -> void:
	if body == self:
		get_tree().call_deferred(
			"change_scene_to_file",
			"res://scenes/forked_forest.tscn"
		)

func _on_exit_to_pendant_body_entered(body: Node2D) -> void:
	if body == self:
		get_tree().call_deferred(
			"change_scene_to_file",
			"res://scenes/pendant_room.tscn"
		)

func _on_exit_to_grove_body_entered(body: Node2D) -> void:
	if body == self:
		get_tree().call_deferred(
			"change_scene_to_file",
			"res://scenes/corrupted_grove.tscn"
		)

func _on_exit_to_boss_body_entered(body: Node2D) -> void:
	if body == self:
		get_tree().call_deferred(
			"change_scene_to_file",
			"res://scenes/boss_room.tscn"
		)


func _on_exit_back_to_forest_body_entered(body: Node2D) -> void:
	if body == self:
		get_tree().call_deferred(
			"change_scene_to_file",
			"res://scenes/forked_forest.tscn"
		)


func _on_exit_to_ending_body_entered(body):
	print("Ending trigger touched")

	if !body.is_in_group("player"):
		print("Not player")
		return

	print("Player detected")

	if !DemoState.eclipse_shard_collected:
		print("Shard not collected")
		return

	print("Loading ending scene")

	get_tree().call_deferred(
		"change_scene_to_file",
		"res://scenes/ui/demo_end.tscn"
	)
