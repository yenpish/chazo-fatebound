extends Node

var music_player: AudioStreamPlayer

func _ready():
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	
	music_player.volume_db = -15.0

	music_player.stream = preload("res://assets/audio/bgm.mp3")
	music_player.play()
