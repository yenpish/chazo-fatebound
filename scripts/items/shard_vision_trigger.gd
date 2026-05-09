extends Area2D

@export_multiline var missing_shard_message: String = "A strange silence lingers. Brakkor's shard is still missing."
@export_multiline var shard_vision_message: String = "The Eclipse Shard of Hunger trembles... somewhere beyond Mossgrave, the Eclipse Gate stirs. Two fragments remain."

var can_trigger: bool = true

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not can_trigger:
		return

	if not body.is_in_group("player"):
		return

	can_trigger = false

	var hud := get_tree().get_first_node_in_group("hud")

	if DemoState.eclipse_shard_collected:
		print("Shard Vision triggered")
		if hud != null and hud.has_method("show_message"):
			hud.show_message(shard_vision_message)
	else:
		print("Shard Vision blocked: shard missing")
		if hud != null and hud.has_method("show_message"):
			hud.show_message(missing_shard_message)

	await get_tree().create_timer(2.0).timeout
	can_trigger = true
