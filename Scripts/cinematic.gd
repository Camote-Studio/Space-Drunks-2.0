extends Control
func _ready() -> void:
	var music = preload("res://Assets/music/funk-house-retro-groovy-dance-216533.mp3")
	SoundEffectManager.music_player.stream = music
	SoundEffectManager.music_player.play()
