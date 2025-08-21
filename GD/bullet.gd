extends Node2D

var SPEED := 200

func _process(delta: float) -> void:
	position += transform.x * SPEED * delta
