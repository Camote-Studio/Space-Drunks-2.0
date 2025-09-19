extends Node2D

func _ready() -> void:
	var music = preload("res://Assets/music/FinalBattle.mp3")
	SoundEffectManager.music_player.stream = music
	SoundEffectManager.music_player.play()
