extends Control

@onready var start_button: Button = $Content/StartButton
@onready var controls_label: Label = $Content/ControlsLabel


func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)

	controls_label.text = "Controls:\nWASD / Arrow Keys - Move\nSpace / Left Click - Attack\nR - Restart"


func _on_start_button_pressed() -> void:
	DemoState.reset_demo_state()
	get_tree().change_scene_to_file("res://scenes/tutorial_room.tscn")
