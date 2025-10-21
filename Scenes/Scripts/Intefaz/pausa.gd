extends CanvasLayer

func _ready() -> void:
	#$Volver.grab_focus()
	
	# Conectar señales del botón
	$Volver.connect("focus_entered", Callable(self, "_on_volver_focus_entered"))
	$Volver.connect("focus_exited", Callable(self, "_on_volver_focus_exited"))

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("start"):
		get_tree().paused = not get_tree().paused
		$TextureRect.visible = not $TextureRect.visible
		$Volver.visible = not $Volver.visible
		$Volver/Label.visible = not $Volver/Label.visible

func _on_volver_pressed() -> void:
	get_tree().paused = not get_tree().paused
	$TextureRect.visible = not $TextureRect.visible
	$Volver.visible = not $Volver.visible
	$Volver/Label.visible = not $Volver/Label.visible

# --- Simulación de hover con focus ---
func _on_volver_focus_entered():
	$Volver.modulate = Color(1.2, 1.2, 1.2) # brillo (hover)

func _on_volver_focus_exited():
	$Volver.modulate = Color(1, 1, 1) # normal
