extends Area2D

@export var SPEED: float = 400.0
@export var lifetime: float = 5.0
var direction: Vector2 = Vector2.RIGHT

@onready var player := get_tree().get_first_node_in_group("players")
@onready var cam := get_tree().get_first_node_in_group("main_camera") as Camera2D

var time_alive := 0.0

func _ready() -> void:
	# Asegurarse de que el Area2D monitorea colisiones
	monitoring = true
	monitorable = true

	# Aplicar posibles poderes del jugador a la bala
	if player and player.has_method("apply_power_to_bullet"):
		player.apply_power_to_bullet(self)

	# Conectar señales de colisión de forma segura
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))
	# También conectar area_entered por si el enemigo es Area2D
	if not is_connected("area_entered", Callable(self, "_on_area_entered")):
		connect("area_entered", Callable(self, "_on_area_entered"))

func _process(delta: float) -> void:
	# Mover bala usando global_position → independiente del jugador
	global_position += direction * SPEED * delta
	time_alive += delta

	# Destruir bala si supera lifetime
	if time_alive >= lifetime:
		queue_free()
		return

	# Destruir bala si sale de cámara
	if cam and not _is_on_screen():
		queue_free()

func _on_body_entered(body: Node) -> void:
	# Evitar errores al chocar con cosas no relevantes
	if body == null or body == self:
		return
	# Opcional: ignorar colisiones con otros bullets o con jugadores si hace falta
	if body.is_in_group("bullets") or body.is_in_group("players"):
		return

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

# Si el enemigo es un Area2D en vez de un PhysicsBody, manejamos también area_entered
func _on_area_entered(area: Area2D) -> void:
	_on_body_entered(area) # reaprovecha la lógica

# Función para revisar si la bala está dentro del viewport de la cámara
func _is_on_screen() -> bool:
	if cam == null:
		return true # si no hay cámara, no destruyas la bala
	var screen_rect := Rect2(
		cam.global_position - cam.zoom * cam.get_viewport_rect().size * 0.5,
		cam.zoom * cam.get_viewport_rect().size
	)
	return screen_rect.has_point(global_position)
