extends Node2D

func _ready():
	$"Sombras_transición/AnimationPlayer".play("Sombra_off")
	$Song_world.play()
