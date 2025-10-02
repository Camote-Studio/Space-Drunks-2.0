extends Area2D

# Escenas de enemigos
const ENEMY = preload("res://Scenes/Enemies/enemie_2.tscn")
const ENEMY2 = preload("res://Scenes/enemie_4.tscn")   # enemigo alternativo

# Referencia a la cámara
@export var cam_path: NodePath

# Límites verticales de spawn
@export var y_min: float = 280.0
@export var y_max: float = 482.0

# Configuración de oleadas
@export var wave_spread: float = 0.3     # retraso aleatorio entre spawns
@export var concurrent_cap: int = 10    # antes 8 → aumentamos cantidad máxima viva
@export var spawn_margin: float = 30.0   # píxeles fuera del viewport

# Posiciones de fases
@export var phase_positions: Array = [1300.0, 2999.0, 5132.0]

# Probabilidad de ENEMY2 (20 %)
@export var enemy2_chance: float = 0.2

var rng := RandomNumberGenerator.new()
var cam: Camera2D
var last_cam_x := 0.0

var wave_active := false
var current_batch_id := 0
var batch_alive := 0
var inflight_scheduled := 0
var alive_total := 0
var enemies_dead := 0
var _scheduling := false

var current_phase := 0

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

	# Activar o detener oleadas según el movimiento de cámara
	if cam_moving and not wave_active and current_phase < phase_positions.size():
		_start_wave()
	elif not cam_moving and wave_active:
		_stop_wave()

	# Spawn continuo mientras la oleada está activa
	if wave_active and not _scheduling:
		_try_spawn_next_batch()

	# Comprobar llegada a fases
	if current_phase < phase_positions.size() and cam.global_position.x >= phase_positions[current_phase]:
		if wave_active:
			_stop_wave()
		current_phase += 1

	last_cam_x = cam.global_position.x

# --- Control de oleadas ---
func _start_wave() -> void:
	wave_active = true
	current_batch_id = 0
	batch_alive = 0
	inflight_scheduled = 0
	print("Oleada iniciada (spawn activo)")

func _stop_wave() -> void:
	wave_active = false
	print("Oleada detenida (spawn pausado)")

# --- Spawning ---
func _try_spawn_next_batch() -> void:
	if not wave_active:
		return

	_scheduling = true

	var free_slots := concurrent_cap - (alive_total + inflight_scheduled)
	if free_slots <= 0:
		_scheduling = false
		return

	# Ahora se pueden spawnear hasta 2 enemigos a la vez
	var to_spawn: int = min(rng.randi_range(1, 2), free_slots)
	current_batch_id += 1
	print("Spawning batch", current_batch_id, "- a spawnear:", to_spawn, "enemigos")

	for i in range(to_spawn):
		var delay := rng.randf_range(0.0, wave_spread)
		_spawn_delayed(delay, current_batch_id)

	_scheduling = false

func _spawn_delayed(delay: float, batch_id: int) -> void:
	await get_tree().create_timer(delay).timeout
	inflight_scheduled = max(0, inflight_scheduled - 1)

	if not wave_active or alive_total >= concurrent_cap:
		return

	var spawn_pos := _get_valid_spawn_position()
	if spawn_pos == Vector2.ZERO:
		print("No se encontró posición válida para spawnear")
		return

	# --- Selección del enemigo con probabilidad ---
	var enemy_scene = ENEMY2 if rng.randf() < enemy2_chance else ENEMY
	var e = enemy_scene.instantiate()
	e.global_position = spawn_pos
	get_parent().add_child(e)

	alive_total += 1
	batch_alive += 1
	print("Enemigo spawned en", spawn_pos, "| Alive total:", alive_total, "| Batch alive:", batch_alive)

	if e.has_signal("died") and not e.is_connected("died", Callable(self, "_on_enemy_died")):
		e.connect("died", Callable(self, "_on_enemy_died").bind(batch_id))
	elif not e.tree_exited.is_connected(Callable(self, "_on_enemy_tree_exited")):
		e.tree_exited.connect(Callable(self, "_on_enemy_tree_exited"))

# --- Posición válida ---
func _get_valid_spawn_position(max_tries: int = 50) -> Vector2:
	if cam == null:
		return Vector2.ZERO

	var screen_rect := get_viewport().get_visible_rect()
	var half_size := screen_rect.size * 0.5 * cam.zoom
	var cam_center := cam.global_position
	var cam_rect := Rect2(cam_center - half_size, screen_rect.size * cam.zoom)

	for i in range(max_tries):
		# Elegimos lado aleatorio: izquierda (-1) o derecha (1)
		var side := rng.randi_range(0, 1) * 2 - 1
		var x_min_side := cam_rect.position.x - spawn_margin if side == -1 else cam_rect.position.x + cam_rect.size.x
		var x_max_side := x_min_side + (spawn_margin * side)
		var x := rng.randf_range(min(x_min_side, x_max_side), max(x_min_side, x_max_side))
		var y := rng.randf_range(y_min, y_max)
		var pos := Vector2(x, y)
		if not cam_rect.has_point(pos):
			return pos

	# Fallback: spawn justo fuera del borde
	var side := rng.randi_range(0, 1) * 2 - 1
	var x := cam_rect.position.x - spawn_margin if side == -1 else cam_rect.position.x + cam_rect.size.x
	var y := rng.randf_range(y_min, y_max)
	return Vector2(x, y)

# --- Eventos de enemigos ---
func _on_enemy_died(batch_id: int) -> void:
	alive_total = max(0, alive_total - 1)
	enemies_dead += 1
	if batch_id == current_batch_id:
		batch_alive = max(0, batch_alive - 1)
	print("Enemigo muerto | Alive:", alive_total, "| Dead:", enemies_dead, "| Batch alive:", batch_alive)

func _on_enemy_tree_exited() -> void:
	alive_total = max(0, alive_total - 1)
	batch_alive = max(0, batch_alive - 1)
	print("Enemigo salido del árbol | Alive:", alive_total, "| Batch alive:", batch_alive)
