extends Node2D

#func _ready():
	#$"Sombras_transición/AnimationPlayer".play("Sombra_off")
	#$Song_world.play()
func _ready() -> void:
	var music = preload("res://Assets/music/Hideki Naganuma - JACK DA FUNK - Bomb Rush Cyberfunk OST.mp3")
	SoundEffectManager.music_player.stream = music
	SoundEffectManager.music_player.play()
