extends Area2D

@export var next_scene_path: String = "res://Scenes/cinematic_level_1_f_3.tscn"
var _scene_change_done := false

func _on_body_entered(body: Node2D) -> void:
	if _scene_change_done:
		return
	
	if body.is_in_group("player") or body.is_in_group("player_2"):
		_scene_change_done = true
		# Espera un frame para evitar dobles llamadas
		await get_tree().process_frame
		# Limpia input para evitar que el jugador dispare/mueva en la escena nueva
		Input.action_release("fired")
		Input.action_release("fired_2")
		get_tree().change_scene_to_file(next_scene_path)
