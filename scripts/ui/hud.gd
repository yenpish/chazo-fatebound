extends CanvasLayer

@onready var hp_label: Label = $HPLabel
@onready var game_over_label: Label = $GameOverLabel

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
