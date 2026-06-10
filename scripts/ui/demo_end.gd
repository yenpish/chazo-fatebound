extends Control

@onready var secret_label: Label = $Content/SecretLabel

func _ready() -> void:
	if DemoState.pendant_collected:
		secret_label.text = "Secret Discovered: Pendant of Malaya"
	else:
		secret_label.text = ""

	fade_out_music()


func fade_out_music() -> void:
	await get_tree().create_timer(4.0).timeout

	if MusicManager.music_player == null:
		return

	var tween = create_tween()

	tween.tween_property(
		MusicManager.music_player,
		"volume_db",
		-80.0,
		3.0
	)

	await tween.finished

	MusicManager.music_player.stop()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		DemoState.reset_demo_state()
		get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")
