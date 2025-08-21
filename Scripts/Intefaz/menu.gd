extends Control

var tipo_boton = null


func _on_start_pressed() -> void:
	tipo_boton = "start"
	$"Sombras_transición".show()
	$"Sombras_transición/Sombra_time".start()
	$"Sombras_transición/AnimationPlayer".play("Sombra_on")
	
func _on_options_pressed() -> void:
	tipo_boton = "options"
	$"Sombras_transición".show()
	$"Sombras_transición/Sombra_time".start()
	$"Sombras_transición/AnimationPlayer".play("Sombra_on")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_sombra_time_timeout() -> void:
	if tipo_boton == 'start' :
		get_tree().change_scene_to_file("res://Scenes/game_world.tscn") 
	
	elif tipo_boton == 'options' :
		get_tree().change_scene_to_file("") #Agregar escena options
		
