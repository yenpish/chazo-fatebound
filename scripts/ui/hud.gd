extends CanvasLayer

@onready var hp_label: Label = $HPLabel

func update_hp(current_hp: int, max_hp: int) -> void:
	if hp_label == null:
		hp_label = get_node_or_null("HPLabel")
	
	if hp_label == null:
		print("HUD error: HPLabel not found")
		return
	
	hp_label.text = "HP: %d / %d" % [current_hp, max_hp]
