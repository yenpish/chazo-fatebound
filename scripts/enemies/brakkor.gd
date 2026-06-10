extends "res://scripts/enemies/enemy_base.gd"

@export var shard_scene: PackedScene
@export var shard_spawn_offset: Vector2 = Vector2(0, 40)

var boss_hp_bar: Node = null


func _ready() -> void:
	max_hp = 8
	move_speed = 90.0
	contact_damage = 1
	damage_cooldown = 0.8
	chase_range = 700.0
	stop_distance = 20.0
	
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	current_hp = max_hp
	original_sprite_modulate = placeholder_sprite.modulate
	find_player()
	
	await get_tree().process_frame

	boss_hp_bar = get_tree().get_first_node_in_group("boss_hp_bar")

	if boss_hp_bar != null and boss_hp_bar.has_method("show_boss_bar"):
		boss_hp_bar.show_boss_bar("Brakkor, the Rootbound Maw", current_hp, max_hp)
	
	print(name, " ready with HP: ", current_hp)


func _physics_process(_delta: float) -> void:
	if is_dead:
		return

	if player == null:
		find_player()

	chase_player()
	
	if placeholder_sprite is AnimatedSprite2D:

		var touching_player := false

		if damage_area != null:
			for body in damage_area.get_overlapping_bodies():
				if body.is_in_group("player"):
					touching_player = true
					break

		if touching_player:
			placeholder_sprite.play("attack1")

		elif velocity.length() > 0:
			placeholder_sprite.play("walk")

		else:
			placeholder_sprite.play("idle")

		if player != null:
			placeholder_sprite.flip_h = player.global_position.x > global_position.x
	
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
	current_hp = max(current_hp, 0)

	print(name, " took ", amount, " damage. HP left: ", current_hp)

	if boss_hp_bar != null and boss_hp_bar.has_method("update_boss_hp"):
		boss_hp_bar.update_boss_hp(current_hp, max_hp)

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
	
	$DeathSFX.play()
	
	velocity = Vector2.ZERO
	print(name, " defeated")

	if boss_hp_bar != null and boss_hp_bar.has_method("update_boss_hp"):
		boss_hp_bar.update_boss_hp(0, max_hp)

	if placeholder_sprite is AnimatedSprite2D:
		placeholder_sprite.play("die")

		await placeholder_sprite.animation_finished
	else:
		await get_tree().create_timer(0.5).timeout

	if boss_hp_bar != null and boss_hp_bar.has_method("hide_boss_bar"):
		boss_hp_bar.hide_boss_bar()

	spawn_eclipse_shard()
	
	var hud := get_tree().get_first_node_in_group("hud")

	if hud != null and hud.has_method("show_message"):
		hud.show_message("BRAKKOR DEFEATED
The Eclipse Shard has appeared.")

	queue_free()

func spawn_eclipse_shard() -> void:
	if shard_scene == null:
		print("Brakkor has no shard_scene assigned.")
		return

	var shard_instance := shard_scene.instantiate() as Node2D

	if shard_instance == null:
		print("Failed to spawn Eclipse Shard.")
		return

	get_parent().add_child(shard_instance)
	shard_instance.global_position = global_position + shard_spawn_offset

	print("Brakkor released Eclipse Shard of Hunger")
