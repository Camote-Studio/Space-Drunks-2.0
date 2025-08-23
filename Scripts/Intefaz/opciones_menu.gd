extends Control

	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):  # Escape por defecto
		get_tree().change_scene_to_file("res://Scenes/Interfaz/Menu.tscn")
