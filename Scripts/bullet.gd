# Tu script bullet.gd CORREGIDO
extends Area2D

@export var SPEED: float = 400.0
@export var lifetime: float = 5.0
var direction: Vector2 = Vector2.RIGHT

# --- CAMBIOS AQUÍ ---
# LÍNEA ELIMINADA: Ya no buscamos al jugador de esta forma.
# @onready var player := get_tree().get_first_node_in_group("players")
# NUEVA VARIABLE: Esta variable la rellenará el script Gun.gd.
var owner_node: Node2D 
# --- FIN DE CAMBIOS ---

@onready var cam := get_tree().get_first_node_in_group("main_camera") as Camera2D
var time_alive := 0.0

func _ready() -> void:
	monitoring = true
	monitorable = true

	# CAMBIO: Usamos owner_node en lugar de 'player'
	if owner_node and owner_node.has_method("apply_power_to_bullet"):
		owner_node.apply_power_to_bullet(self)

	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))
	if not is_connected("area_entered", Callable(self, "_on_area_entered")):
		connect("area_entered", Callable(self, "_on_area_entered"))

func _process(delta: float) -> void:
	global_position += direction * SPEED * delta
	time_alive += delta
	if time_alive >= lifetime:
		queue_free()
		return
	if cam and not _is_on_screen():
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body == null or body == self or body.is_in_group("bullets") or body.is_in_group("players"):
		return

	var did_hit := false
	var dmg := 0.0

	# Tu lógica de daño está perfecta, no necesita cambios.
	if (body.is_in_group("enemy_1") or body.is_in_group("enemy_2")) and body.has_signal("damage"):
		dmg = 30.0
		body.emit_signal("damage", dmg)
		did_hit = true
	# ... (tus otros elif para enemigos) ...
	elif body.is_in_group("boss") and body.has_signal("damage"):
		dmg = 10.0
		body.emit_signal("damage", dmg)
		did_hit = true

	if did_hit:
		# CAMBIO: Usamos owner_node en lugar de 'player'
		if owner_node and owner_node.has_method("gain_ability_from_attack"):
			owner_node.gain_ability_from_attack(dmg)
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	_on_body_entered(area)

func _is_on_screen() -> bool:
	if cam == null: return true
	var screen_rect := Rect2(cam.global_position - cam.zoom * cam.get_viewport_rect().size * 0.5, cam.zoom * cam.get_viewport_rect().size)
	return screen_rect.has_point(global_position)
