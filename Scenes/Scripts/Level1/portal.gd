extends Node2D


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var root = get_tree()
		if root != null:
			root.change_scene_to_file("res://Scenes/Level1_F2.tscn")
	if body.is_in_group("player_2"):
		var root = get_tree()
		if root != null:
			root.change_scene_to_file("res://Scenes/Level1_F2.tscn")
