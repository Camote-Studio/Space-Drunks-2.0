extends Node2D

var SPEED := 200

func _process(delta: float) -> void:
	position += transform.x * SPEED * delta
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy_1"):
		body.emit_signal("damage", 10.0)
		queue_free()
		
