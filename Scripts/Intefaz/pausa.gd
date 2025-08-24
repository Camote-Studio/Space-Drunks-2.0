extends CanvasLayer


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("start"):
		get_tree().paused = not get_tree().paused
		$TextureRect.visible = not $TextureRect.visible
