extends Node2D

var SPEED := 200

@onready var player := get_tree().get_first_node_in_group("players")
@onready var cam := get_tree().get_first_node_in_group("main_camera") as Camera2D

func _ready() -> void:
	if player and player.has_method("apply_power_to_bullet"):
		player.apply_power_to_bullet(self)

func _process(delta: float) -> void:
	position += transform.x * SPEED * delta

	# Revisar si la bala salió de la cámara
	if cam and not _is_on_screen():
		queue_free() # destruye la bala si ya no se ve

func _on_area_2d_body_entered(body: Node2D) -> void:
	var did_hit := false
	var dmg := 0.0

	if (body.is_in_group("enemy_1") or body.is_in_group("enemy_2")) and body.has_signal("damage"):
		dmg = 30.0
		body.emit_signal("damage", dmg)
		did_hit = true
	elif body.is_in_group("enemy_3") and body.has_signal("damage"):
		dmg = 10.0
		body.emit_signal("damage", dmg)
		did_hit = true
	elif body.is_in_group("enemy_4") and body.has_signal("damage"):
		dmg = 10.0
		body.emit_signal("damage", dmg)
		did_hit = true
	elif body.is_in_group("enemy_5") and body.has_signal("damage"):
		dmg = 20.0
		body.emit_signal("damage", dmg)
		did_hit = true
	elif body.is_in_group("boss") and body.has_signal("damage"):
		dmg = 10.0
		body.emit_signal("damage", dmg)
		did_hit = true

	if did_hit:
		if player and player.has_method("gain_ability_from_attack"):
			player.gain_ability_from_attack(dmg)
		queue_free()


# Función para revisar si la bala está dentro del viewport de la cámara
func _is_on_screen() -> bool:
	if cam == null:
		return true # si no hay cámara, no destruyas la bala
	var screen_rect := Rect2(
		cam.global_position - cam.zoom * cam.get_viewport_rect().size * 0.5,
		cam.zoom * cam.get_viewport_rect().size
	)
	return screen_rect.has_point(global_position)
