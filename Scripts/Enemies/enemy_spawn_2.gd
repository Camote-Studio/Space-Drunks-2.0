extends Area2D

# Escena del enemigo
const ENEMY: PackedScene = preload("res://Scenes/Enemies/enemie_2.tscn")

# Referencia a la cámara
@export var cam_path: NodePath

# Límites verticales de spawn
@export var y_min: float = 280.0
@export var y_max: float = 482.0

# Configuración de oleadas
@export var wave_spread: float = 0.7        # retraso aleatorio entre spawns
@export var concurrent_cap: int = 10        # enemigos vivos al mismo tiempo
@export var spawn_margin: float = 100.0     # píxeles fuera del viewport para spawn
@export var batch_size: int = 3             # enemigos por batch

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var cam: Camera2D
var last_cam_x: float = 0.0

var wave_active: bool = false
var inflight_scheduled: int = 0
var alive_total: int = 0
var enemies_dead: int = 0
var _scheduling: bool = false

func _ready() -> void:
	rng.randomize()
	cam = get_node_or_null(cam_path) as Camera2D
	if cam == null:
		cam = get_tree().get_first_node_in_group("main_camera") as Camera2D
	if cam:
		last_cam_x = cam.global_position.x
	set_process(true)

func _process(_delta: float) -> void:
	if cam == null:
		return

	var cam_moving: bool = abs(cam.global_position.x - last_cam_x) > 0.1

	# Activar o detener spawn según el movimiento de cámara
	wave_active = cam_moving

	# Spawn continuo
	if wave_active and not _scheduling:
		_try_spawn_next_batch()

	last_cam_x = cam.global_position.x

# --- Spawn ---
func _try_spawn_next_batch() -> void:
	if not wave_active:
		return

	var free_slots: int = concurrent_cap - (alive_total + inflight_scheduled)
	if free_slots <= 0:
		return

	var to_spawn: int = min(batch_size, free_slots)
	_scheduling = true

	for i in range(to_spawn):
		var delay: float = rng.randf_range(0.0, wave_spread)
		inflight_scheduled += 1
		_spawn_delayed(delay)

	_scheduling = false

func _spawn_delayed(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	inflight_scheduled = max(0, inflight_scheduled - 1)

	if not wave_active or alive_total >= concurrent_cap:
		return

	var spawn_pos: Vector2 = _get_valid_spawn_position()
	if spawn_pos == Vector2.ZERO:
		return

	var e: Node2D = ENEMY.instantiate() as Node2D
	e.global_position = spawn_pos
	get_parent().add_child(e)

	alive_total += 1

	if e.has_signal("died") and not e.is_connected("died", Callable(self, "_on_enemy_died")):
		e.connect("died", Callable(self, "_on_enemy_died"))
	elif not e.tree_exited.is_connected(Callable(self, "_on_enemy_tree_exited")):
		e.tree_exited.connect(Callable(self, "_on_enemy_tree_exited"))

# --- Posición válida ---
func _get_valid_spawn_position(max_tries: int = 50) -> Vector2:
	if cam == null:
		return Vector2.ZERO

	var screen_rect: Rect2 = get_viewport().get_visible_rect()
	var half_size: Vector2 = screen_rect.size * 0.5 * cam.zoom
	var cam_center: Vector2 = cam.global_position
	var cam_rect: Rect2 = Rect2(cam_center - half_size, screen_rect.size * cam.zoom)

	for i in range(max_tries):
		# Lado aleatorio: -1 = izquierda, 1 = derecha
		var side: int = rng.randi_range(0, 1) * 2 - 1
		var x: float = 0.0
		if side == -1:
			x = cam_rect.position.x - rng.randf_range(spawn_margin, spawn_margin + 150)
		else:
			x = cam_rect.position.x + cam_rect.size.x + rng.randf_range(spawn_margin, spawn_margin + 150)
		var y: float = rng.randf_range(y_min, y_max)
		var pos: Vector2 = Vector2(x, y)
		if not cam_rect.has_point(pos):
			return pos

	# Fallback: spawn justo fuera del borde
	var side: int = rng.randi_range(0, 1) * 2 - 1
	var x: float = cam_rect.position.x - spawn_margin if side == -1 else cam_rect.position.x + cam_rect.size.x + spawn_margin
	var y: float = rng.randf_range(y_min, y_max)
	return Vector2(x, y)

# --- Eventos de enemigos ---
func _on_enemy_died() -> void:
	alive_total = max(0, alive_total - 1)
	enemies_dead += 1

func _on_enemy_tree_exited() -> void:
	alive_total = max(0, alive_total - 1)
