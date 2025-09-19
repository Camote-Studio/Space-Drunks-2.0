extends Control

var tipo_boton = null


func _ready() -> void:
	var music = preload("res://Assets/music/624874__sonically_sound__retro-funk-20032022-1714.wav")
	SoundEffectManager.music_player.stream = music
	SoundEffectManager.music_player.play()
	
	$"Sombras_transición".show()
	$"Sombras_transición/AnimationPlayer".play("Sombra_off")
	
	
	#ANIMACIÓN CON SHADERS SOLO AFECTA A LOS HIJOS DEL NODO CONTROL (SPRITE2D_TITULO, BOTONES):
	for button in get_tree().get_nodes_in_group("ui_botones"):
		if button is TextureButton:
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.focus_mode = Control.FOCUS_ALL  # Sigue respondiendo a teclado/mando
	#$Start.grab_focus()

func _on_start_pressed() -> void:
	tipo_boton = "start"
	$"Sombras_transición".show()
	$"Sombras_transición/Sombra_time".start()
	$"Sombras_transición/AnimationPlayer".play("Sombra_on")


func _on_tutorial_pressed() -> void:
	tipo_boton = "tutorial"
	Laptop.change_scene("res://Tutorial.tscn", "abrir_laptop")
	

func _on_options_pressed() -> void:
	tipo_boton = "options"
	$"Sombras_transición".show()
	$"Sombras_transición/Sombra_time".start()
	$"Sombras_transición/AnimationPlayer".play("Sombra_on")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_sombra_time_timeout() -> void:
	if tipo_boton == 'start' :
		get_tree().change_scene_to_file("res://Scenes/loading_screen.tscn") 
	
	elif tipo_boton == 'options' :
		get_tree().change_scene_to_file("res://Scenes/Interfaz/Opciones_Menu.tscn") 
		


		
