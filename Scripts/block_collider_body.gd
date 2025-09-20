extends Area2D

# Elige el lado en el Inspector con nombres legibles
@export_enum("LEFT", "RIGHT", "TOP", "BOTTOM") var side: int = 0
@export var push_strength: float = 30.0

@onready var warning_label: Label = $warning_label
@onready var warning_timer: Timer = $"../warning_timer"

func _ready() -> void:
	if warning_timer:
		warning_timer.start()

func _process(_delta: float) -> void:
	# Mueve el área a la par de la cámara principal (grupo "main_camera")
	var cam := get_tree().get_first_node_in_group("main_camera")
	if cam:
		# sigue solo en X (cambia a global_position = cam.global_position si quieres seguir X e Y)
		global_position.x = cam.global_position.x

func _on_body_entered(body: Node2D) -> void:
	if not (body.is_in_group("player") or body.is_in_group("player_2")):
		return

	var push_dir := _get_push_dir(body)
	body.global_position -= push_dir * push_strength

	# Mensaje de advertencia donde choca el jugador
	if warning_label:
		warning_label.global_position = body.global_position
		warning_label.visible = true

func _on_warning_timer_timeout() -> void:
	if warning_label:
		warning_label.visible = false

func _get_push_dir(body: Node2D) -> Vector2:
	match side:
		0:  # LEFT  → empuja a la derecha
			return Vector2(1, 0)
		1:  # RIGHT → empuja a la izquierda
			return Vector2(-1, 0)
		2:  # TOP   → empuja hacia abajo
			return Vector2(0, 1)
		3:  # BOTTOM→ empuja hacia arriba
			return Vector2(0, -1)
		_:  # fallback por si acaso
			return (body.global_position - global_position).normalized()
