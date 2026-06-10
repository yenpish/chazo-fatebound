extends CharacterBody2D

@export var move_speed := 40.0
@export var attack_range := 45.0
@export var attack_cooldown := 1.0

var player: Node2D
var cooldown_timer := 0.0

func _ready():
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if player == null:
		return

	cooldown_timer -= delta

	var distance = global_position.distance_to(player.global_position)

	if distance > attack_range:
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * move_speed
	else:
		velocity = Vector2.ZERO

	if distance <= attack_range and cooldown_timer <= 0:
		if player.has_method("take_damage"):
			player.take_damage(1)
		cooldown_timer = attack_cooldown

	move_and_slide()

func take_damage(_amount):
	print("Slime hit!")
	queue_free()
