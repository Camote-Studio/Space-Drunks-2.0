extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	animation_player.play("Cine")
	var music = preload("res://Assets/music/funk-house-retro-groovy-dance-216533.mp3")
	SoundEffectManager.music_player.stream = music
	SoundEffectManager.music_player.play()

func _on_AnimationPlayer_animation_finished(anim_name: String):
	if anim_name == "Cine":
		get_tree().change_scene_to_file("res://Scenes/Menu.tscn")
