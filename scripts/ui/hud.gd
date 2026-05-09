extends CanvasLayer

@onready var hp_label: Label = $HPLabel
@onready var game_over_label: Label = $GameOverLabel
@onready var message_label: Label = $MessageLabel

var message_timer_id: int = 0

func _ready() -> void:
	setup_message_label()

func setup_message_label() -> void:
	if message_label == null:
		message_label = get_node_or_null("MessageLabel")

	if message_label == null:
		print("HUD error: MessageLabel not found")
		return

	message_label.position = Vector2(16, 54)
	message_label.size = Vector2(480, 90)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.clip_text = true
	message_label.visible = false

func update_hp(current_hp: int, max_hp: int) -> void:
	if hp_label == null:
		hp_label = get_node_or_null("HPLabel")
	
	if hp_label == null:
		print("HUD error: HPLabel not found")
		return
	
	hp_label.text = "HP: %d / %d" % [current_hp, max_hp]

func show_game_over() -> void:
	if game_over_label == null:
		game_over_label = get_node_or_null("GameOverLabel")
	
	if game_over_label == null:
		print("HUD error: GameOverLabel not found")
		return
	
	game_over_label.visible = true

func show_message(message: String) -> void:
	print(message)

	if message_label == null:
		message_label = get_node_or_null("MessageLabel")

	if message_label == null:
		print("HUD error: MessageLabel not found")
		return

	message_timer_id += 1
	var current_timer_id := message_timer_id

	message_label.text = message
	message_label.visible = true

	await get_tree().create_timer(3.0).timeout

	if current_timer_id == message_timer_id and message_label != null:
		message_label.visible = false
