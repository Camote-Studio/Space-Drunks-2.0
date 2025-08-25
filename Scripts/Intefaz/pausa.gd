extends CanvasLayer


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("start"):
		get_tree().paused = not get_tree().paused
		$TextureRect.visible = not $TextureRect.visible
		$Salir.visible = not $Salir.visible
		$Salir/Label.visible = not $Salir/Label.visible

func _on_salir_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Interfaz/Menu.tscn")
	
	
