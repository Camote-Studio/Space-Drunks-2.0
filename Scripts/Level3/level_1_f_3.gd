extends Node2D


func _on_area_2d_body_entered(body: Node2D) -> void:
		$"Sombras_transición/AnimationPlayer".play("Sombra_off")
		get_tree().change_scene_to_file("res://Scenes/Interfaz/GANASTE.tscn")
	
	
	
