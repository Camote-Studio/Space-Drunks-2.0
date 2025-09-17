extends Control
@onready var test_effect_sound: AudioStreamPlayer2D = $test_effect_sound

	
func _ready():
	$"Sombras_transición".show()
	$"Sombras_transición/AnimationPlayer".play("Sombra_off")
	
	for button in get_tree().get_nodes_in_group("ui_boton_opciones"):
		if button is TextureButton:
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.focus_mode = Control.FOCUS_ALL  # Sigue respondiendo a teclado/mando
	$Quit_menu.grab_focus()

	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):  # Escape por defecto
		get_tree().change_scene_to_file("res://Scenes/Interfaz/Menu.tscn")


func _on_quit_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Interfaz/Menu.tscn")


func _on_sound_effect_scroller_drag_started() -> void:
	$test_effect_sound.play()
