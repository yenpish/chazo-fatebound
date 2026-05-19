extends Node

var debug_enabled: bool = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):
		debug_enabled = !debug_enabled

		if debug_enabled:
			print("DEBUG MODE: ON")
		else:
			print("DEBUG MODE: OFF")
