extends Node2D

func _ready():
	$"Sombras_transición/AnimationPlayer".play("Sombra_off")
	var music = preload("res://Assets/music/funk-house-retro-groovy-dance-216533.mp3")
	SoundEffectManager.music_player.stream = music
	SoundEffectManager.music_player.play()
