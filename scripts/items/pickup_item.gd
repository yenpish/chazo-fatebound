extends Area2D

@export var item_id: String = ""
@export var item_name: String = "Item"
@export_multiline var pickup_message: String = "Item collected."

var collected: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if collected:
		return

	if not body.is_in_group("player"):
		return

	collected = true
	print(item_name, " collected")

	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("show_message"):
		hud.show_message(pickup_message)

	queue_free()
