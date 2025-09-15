extends Node2D

@export var SPEED: float = 400.0
@export var lifetime: float = 5.0
var direction: Vector2 = Vector2.RIGHT

@onready var player := get_tree().get_first_node_in_group("players")
@onready var cam := get_tree().get_first_node_in_group("main_camera") as Camera2D

var time_alive := 0.0

func _ready() -> void:
	# Aplica posibles poderes del jugador a la bala
	if player and player.has_method("apply_power_to_bullet"):
		player.apply_power_to_bullet(self)
	# Conectar la señal de colisión si no está conectada
	if not is_connected("body_entered", Callable(self, "_on_area_2d_body_entered")):
		connect("body_entered", Callable(self, "_on_area_2d_body_entered"))

func _process(delta: float) -> void:
	# Mover bala usando global_position → independiente del jugador
	global_position += direction * SPEED * delta
	time_alive += delta

	# Destruir bala si sale de cámara o supera lifetime
	if cam and not _is_on_screen():
		queue_free()
	elif time_alive >= lifetime:
		queue_free()

func _on_area_2d_body_entered(body: Node) -> void:
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
		return true
	var screen_rect := Rect2(
		cam.global_position - cam.zoom * cam.get_viewport_rect().size * 0.5,
		cam.zoom * cam.get_viewport_rect().size
	)
	return screen_rect.has_point(global_position)
