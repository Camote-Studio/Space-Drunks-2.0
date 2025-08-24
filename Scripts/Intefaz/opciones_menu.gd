extends Control
@onready var test_effect_sound: AudioStreamPlayer2D = $test_effect_sound

	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):  # Escape por defecto
		get_tree().change_scene_to_file("res://Scenes/Interfaz/Menu.tscn")


func _on_quit_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Interfaz/Menu.tscn")


func _on_sound_effect_scroller_drag_started() -> void:
	$test_effect_sound.play()
