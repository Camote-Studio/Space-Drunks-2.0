extends Node2D

var SPEED := 200

# Referencia rápida al jugador (usa el grupo "players" de tu script del player)
@onready var player := get_tree().get_first_node_in_group("players")

func _ready() -> void:
	# Si el próximo disparo estaba potenciado, aplícalo a ESTA bala
	# (no pasa nada si el player no tiene ese método)
	if player and player.has_method("apply_power_to_bullet"):
		player.apply_power_to_bullet(self)

func _process(delta: float) -> void:
	position += transform.x * SPEED * delta

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

	# Si hicimos daño, carga la barra de habilidad del player con ese daño
	if did_hit:
		if player and player.has_method("gain_ability_from_attack"):
			player.gain_ability_from_attack(dmg)
		queue_free()
