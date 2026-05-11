extends Control

@onready var secret_label: Label = $Content/SecretLabel

func _ready() -> void:
	if DemoState.pendant_collected:
		secret_label.text = "Secret Discovered: Pendant of Malaya"
	else:
		secret_label.text = ""


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		DemoState.reset_demo_state()
		get_tree().change_scene_to_file("res://scenes/levels/mossgrave_outskirts.tscn")
