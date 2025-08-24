extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer
func _ready() -> void:
	
	animation_player.play("Cine")
	var music = preload("res://Assets/music/funk-house-retro-groovy-dance-216533.mp3")
	SoundEffectManager.music_player.stream = music
	SoundEffectManager.music_player.play()
	# Espera 10 segundos antes de cambiar de escena
	await get_tree().create_timer(54.0).timeout
	$"Sombras_transición/AnimationPlayer".play("Sombra_off")
	get_tree().change_scene_to_file("res://Scenes/Interfaz/Menu.tscn")

func _on_AnimationPlayer_animation_finished(anim_name: String):
	if anim_name == "Cine":
		get_tree().change_scene_to_file("res://Scenes/Menu.tscn")

	
func _process(delta):
	if Input.is_action_just_pressed("start"):
		$"Sombras_transición/AnimationPlayer".play("Sombra_off")
		get_tree().change_scene_to_file("res://Scenes/Interfaz/Menu.tscn")
