extends Area2D

# --- Pool de enemigos aleatorios (1–4) ---
const ENEMY1 = preload("res://Scenes/Enemies/enemie_1.tscn")
const ENEMY2 = preload("res://Scenes/Enemies/enemie_2.tscn")
const ENEMY3 = preload("res://Scenes/enemie_3.tscn")
const ENEMY4 = preload("res://Scenes/enemie_4.tscn") # <- corregida la ruta
const MOVE_ENEMY_POOL := [ENEMY1, ENEMY2, ENEMY3, ENEMY4]

@export var cam_path: NodePath

# Puntos a los que mover la cámara después de cada tramo
@export var x_after_phase1: float = 2999.0
@export var x_after_phase2: float = 5132.0

# --- Configuración de spawns aleatorios durante los trayectos ---
@export var move_spawn_count_per_travel: int = 6     # cuántos enemigos por trayecto
@export var move_spawn_y_min: float = 292.0
@export var move_spawn_y_max: float = 481.0
@export var move_spawn_x_offset_from_cam: float = 0
@export var move_spawn_spread_jitter: float = 0.15

# “Más lento”: multiplica los tiempos base entre spawns ( >1.0 = más lento )
@export var spawn_pacing_mult: float = 1.35

# Velocidad de cámara (si no usamos go_to_x de tu cámara)
@export var fallback_cam_speed_px_s: float = 60.0
@export var cam_tween_trans := Tween.TRANS_SINE
@export var cam_tween_ease := Tween.EASE_IN_OUT

# --- Arranque estático / espera de spawner anterior ---
# Opción A: esperar a que la cámara deje de moverse
@export var start_when_camera_stops: bool = true
@export var cam_still_threshold_px: float = 0.6  # px por frame para considerar “quieta”
@export var cam_still_frames_needed: int = 8     # nº de frames seguidos quieta

# Opción B (alternativa): esperar a que la cámara llegue a un X concreto
@export var start_after_cam_reaches_x: bool = false
@export var start_trigger_x: float = 0.0

@export var debug_logs := false

var rng := RandomNumberGenerator.new()
var cam: Camera2D
var _cam_tween: Tween
var _active_move_timers: Array[Timer] = []

# --- Estados ---
const S_WAIT_START  := 0  # espera estática hasta que la cámara se quede quieta o llegue a un X
const S_TRAVEL1     := 1
const S_TRAVEL2     := 2
const S_DONE        := 3
var state: int = S_WAIT_START

# Para detectar “cámara quieta”
var _prev_cam_pos := Vector2.ZERO
var _still_frames := 0

func _ready() -> void:
	rng.randomize()

	# Referencia a la cámara
	if cam_path != NodePath():
		cam = get_node_or_null(cam_path) as Camera2D
	if cam == null:
		cam = get_tree().get_first_node_in_group("main_camera") as Camera2D
	if cam == null and get_viewport():
		cam = get_viewport().get_camera_2d()

	if cam:
		_prev_cam_pos = cam.global_position

	set_process(true)
	state = S_WAIT_START
	if debug_logs: print("[Spawner] READY → esperando arranque (cámara estática / trigger X)")

# --- Movimiento de cámara ---
func _start_camera_move_to(target_x: float) -> void:
	if cam == null: return

	if cam.has_method("go_to_x"):
		cam.call("go_to_x", target_x)  # tu cámara lo moverá suave a ~60 px/s (según la tengas)
	else:
		if _cam_tween and _cam_tween.is_running():
			_cam_tween.kill()
		var start_x := cam.global_position.x
		var dx = abs(target_x - start_x)
		var dur = dx / max(fallback_cam_speed_px_s, 1.0)
		_cam_tween = create_tween().set_trans(cam_tween_trans).set_ease(cam_tween_ease)
		_cam_tween.tween_property(cam, "global_position:x", target_x, dur)

func _camera_reached_x(target_x: float) -> bool:
	if cam == null: return true
	return abs(cam.global_position.x - target_x) <= 0.8

# --- Spawns aleatorios durante viajes ---
func _schedule_move_spawns_during_travel(target_x: float) -> void:
	_cancel_move_spawns()
	if move_spawn_count_per_travel <= 0 or cam == null: return

	var start_x := cam.global_position.x
	var dx = abs(target_x - start_x)
	var travel_duration = dx / max(fallback_cam_speed_px_s, 1.0)

	var count = move_spawn_count_per_travel
	var base = max(0.05, travel_duration / float(count + 1)) * max(0.1, spawn_pacing_mult)

	for i in range(count):
		var t := Timer.new()
		t.one_shot = true
		add_child(t)
		_active_move_timers.append(t)

		var jitter = clamp(move_spawn_spread_jitter, 0.0, 0.5)
		var delay = base * float(i + 1) * (1.0 + rng.randf_range(-jitter, jitter))
		t.start(delay)
		t.timeout.connect(_on_move_spawn_timeout.bind(t))

	if debug_logs:
		print("[Spawner] Scheduled ", count, " random enemies over ~", travel_duration, "s (pacing x", spawn_pacing_mult, ")")

func _on_move_spawn_timeout(t: Timer) -> void:
	if state not in [S_TRAVEL1, S_TRAVEL2]:
		if t: _active_move_timers.erase(t); t.queue_free()
		return

	_spawn_random_move_enemy()
	if t: _active_move_timers.erase(t); t.queue_free()

func _spawn_random_move_enemy() -> void:
	if cam == null or MOVE_ENEMY_POOL.is_empty(): return
	var scene: PackedScene = MOVE_ENEMY_POOL[rng.randi() % MOVE_ENEMY_POOL.size()]
	var e = scene.instantiate()

	# Decidir lado: 0 = izquierda, 1 = derecha
	var side = rng.randi() % 2
	var half_width = 1152 / 2  # tamaño del viewport / 2
	var spawn_offset = 100.0    # qué tan fuera del viewport aparecerá

	var px: float
	if side == 0:
		px = cam.global_position.x - half_width - spawn_offset  # fuera a la izquierda
	else:
		px = cam.global_position.x + half_width + spawn_offset  # fuera a la derecha

	# Altura dentro de los límites
	var py = rng.randf_range(move_spawn_y_min, move_spawn_y_max)

	e.global_position = Vector2(px, py)
	get_parent().add_child(e)

	if debug_logs:
		print("[Spawner] Spawned enemy outside viewport at ", px, ",", py)

func _cancel_move_spawns() -> void:
	for t in _active_move_timers:
		if is_instance_valid(t):
			t.stop()
			t.queue_free()
	_active_move_timers.clear()

# --- LOOP ---
func _process(_delta: float) -> void:
	match state:
		S_WAIT_START:
			if cam == null:
				# Sin cámara, arrancamos igual
				state = S_TRAVEL1
				_start_camera_move_to(x_after_phase1)
				_schedule_move_spawns_during_travel(x_after_phase1)
				if debug_logs: print("[Spawner] Sin cámara → TRAVEL1")
				return

			var pos := cam.global_position
			var moved_px := (pos - _prev_cam_pos).length()
			_prev_cam_pos = pos

			var ok_by_still := false
			if start_when_camera_stops:
				if moved_px <= cam_still_threshold_px:
					_still_frames += 1
				else:
					_still_frames = 0
				ok_by_still = _still_frames >= cam_still_frames_needed

			var ok_by_target := false
			if start_after_cam_reaches_x:
				ok_by_target = _camera_reached_x(start_trigger_x)

			# Si se cumple cualquiera de las condiciones (o ambas activadas y se cumplen),
			# arrancamos el primer trayecto.
			var can_start := false
			if start_when_camera_stops and start_after_cam_reaches_x:
				can_start = ok_by_still and ok_by_target
			elif start_when_camera_stops:
				can_start = ok_by_still
			elif start_after_cam_reaches_x:
				can_start = ok_by_target
			else:
				# Si no activaste ninguna condición, arranca de inmediato
				can_start = true

			if can_start:
				state = S_TRAVEL1
				_start_camera_move_to(x_after_phase1)
				_schedule_move_spawns_during_travel(x_after_phase1)
				if debug_logs: print("[Spawner] START → TRAVEL1")
		S_TRAVEL1:
			if _camera_reached_x(x_after_phase1):
				_cancel_move_spawns()
				state = S_TRAVEL2
				_start_camera_move_to(x_after_phase2)
				_schedule_move_spawns_during_travel(x_after_phase2)
				if debug_logs: print("[Spawner] Reached x_after_phase1 → TRAVEL2")
		S_TRAVEL2:
			if _camera_reached_x(x_after_phase2):
				_cancel_move_spawns()
				state = S_DONE
				if debug_logs: print("[Spawner] Reached x_after_phase2 → DONE")
		_:
			pass
