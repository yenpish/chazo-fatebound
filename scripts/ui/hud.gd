extends CanvasLayer

@onready var heart_container: HBoxContainer = $HeartContainer
@onready var hp_label: Label = $HPLabel
@onready var game_over_label: Label = $GameOverLabel
@onready var message_label: Label = $MessageLabel

const HEART_FULL_TEXTURE: Texture2D = preload("res://assets/sprites/hp-bar-full-chazo.png")
const HEART_EMPTY_TEXTURE: Texture2D = preload("res://assets/sprites/hp-bar-empty-chazo.png")

var message_queue: Array[String] = []
var is_showing_message: bool = false

func _ready() -> void:
	setup_message_label()
	game_over_label.visible = false
	hp_label.visible = false

	var player = get_tree().get_first_node_in_group("player")

	if player:
		if not player.hp_changed.is_connected(update_hp):
			player.hp_changed.connect(update_hp)

		if not player.player_died.is_connected(show_game_over):
			player.player_died.connect(show_game_over)
			
		update_hp(player.current_hp, player.max_hp)

func setup_message_label() -> void:
	message_label.position = Vector2(125, 100)
	message_label.size = Vector2(900, 80)

	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.clip_text = false
	message_label.visible = false

func update_hp(current_hp: int, max_hp: int) -> void:
	# Backup text version, hidden for now.
	hp_label.text = "HP: " + str(current_hp) + " / " + str(max_hp)

	update_hearts(current_hp, max_hp)


func update_hearts(current_hp: int, max_hp: int) -> void:
	for child in heart_container.get_children():
		child.queue_free()

	for i in range(max_hp):
		var heart := TextureRect.new()

		if i < current_hp:
			heart.texture = HEART_FULL_TEXTURE
		else:
			heart.texture = HEART_EMPTY_TEXTURE

		heart.custom_minimum_size = Vector2(32, 32)
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		heart_container.add_child(heart)


func show_game_over() -> void:
	game_over_label.visible = true
	game_over_label.text = "GAME OVER\nPress R to restart"


func show_message(message: String) -> void:
	print(message)

	message_label.modulate = Color.RED

	message_queue.append(message)

	if not is_showing_message:
		process_message_queue()


func process_message_queue() -> void:
	is_showing_message = true

	while message_queue.size() > 0:
		var next_message: String = message_queue.pop_front() as String

		message_label.text = next_message
		message_label.visible = true

		await get_tree().create_timer(3.0).timeout

	message_label.visible = false
	is_showing_message = false
