extends Area2D

@export_multiline var missing_shard_message: String = "The path ahead remains silent. Brakkor's shard is still missing."
@export_multiline var end_message: String = "The vision fades... Chazo steps beyond Mossgrave."
@export var end_scene_path: String = "res://scenes/ui/demo_end.tscn"
@export var transition_delay: float = 1.5

var triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if triggered:
		return

	if not body.is_in_group("player"):
		return

	var hud := get_tree().get_first_node_in_group("hud")

	if not DemoState.eclipse_shard_collected:
		return

	triggered = true

	if hud != null and hud.has_method("show_message"):
		hud.show_message(end_message)

	await get_tree().create_timer(transition_delay).timeout

	get_tree().change_scene_to_file(end_scene_path)
