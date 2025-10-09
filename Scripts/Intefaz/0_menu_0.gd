extends Node2D

func _ready():
	$Label/AnimationPlayer.play("Boton_Start")
	
	
func _process(delta):
	if Input.is_action_just_pressed("start"):
		$"Sombras_transición/AnimationPlayer".play("Sombra_off")
		get_tree().change_scene_to_file("res://Scenes/Interfaz/Animaciones_Cinematicas/cinematic.tscn")
		
