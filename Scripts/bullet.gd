extends Node2D

var SPEED := 200

func _process(delta: float) -> void:
	position += transform.x * SPEED * delta
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	if (body.is_in_group("enemy_1") or body.is_in_group("enemy_2")) and body.has_signal("damage"):
		body.emit_signal("damage", 100.0)
		queue_free()
		
