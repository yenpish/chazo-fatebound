extends CanvasLayer

@onready var heart_container: HBoxContainer = $HeartContainer
@onready var hp_label: Label = $HPLabel
@onready var game_over_label: Label = $GameOverLabel
@onready var message_label: Label = $MessageLabel

const HEART_FULL_TEXTURE: Texture2D = preload("res://assets/sprites/hp-bar-full-chazo.png")
const HEART_EMPTY_TEXTURE: Texture2D = preload("res://assets/sprites/hp-bar-empty-chazo.png")

var message_timer_id: int = 0

func _ready() -> void:
	setup_message_label()
	game_over_label.visible = false
	hp_label.visible = false

func setup_message_label() -> void:
	message_label.position = Vector2(16, 54)
	message_label.size = Vector2(480, 90)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.clip_text = true
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

	message_timer_id += 1
	var current_timer_id := message_timer_id

	message_label.text = message
	message_label.visible = true

	await get_tree().create_timer(3.0).timeout

	if current_timer_id == message_timer_id:
		message_label.visible = false
