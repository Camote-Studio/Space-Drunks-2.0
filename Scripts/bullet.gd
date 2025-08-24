extends Node2D

var SPEED := 200

func _process(delta: float) -> void:
	position += transform.x * SPEED * delta
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	if (body.is_in_group("enemy_1") or body.is_in_group("enemy_2")) and body.has_signal("damage"):
		body.emit_signal("damage", 30.0)
		queue_free()
	elif body.is_in_group("enemy_3") and body.has_signal("damage"):
		body.emit_signal("damage", 10.0)
		queue_free()
	elif body.is_in_group("enemy_4") and body.has_signal("damage"):
		body.emit_signal("damage", 10.0)
		queue_free()
	elif body.is_in_group("enemy_5") and body.has_signal("damage"):
		body.emit_signal("damage", 20.0)
		queue_free()
	elif body.is_in_group("boss") and body.has_signal("damage"):
		body.emit_signal("damage", 10.0)
		queue_free()
