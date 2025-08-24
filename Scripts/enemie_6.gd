extends Area2D
const ENEMY = preload("res://Scenes/enemie_5.tscn")

@export var cam_path: NodePath

@export var phase1_max_spawns: int = 3
@export var phase1_x_spawn: float = 1734.0
@export var phase1_y_min: float = 204.0
@export var phase1_y_max: float = 482.0
@export var x_after_phase1: float = 2999.0

@export var phase2_max_spawns: int = 3
@export var phase2_x_spawn: float = 2999.0
@export var phase2_y_min: float = 204.0
@export var phase2_y_max: float = 482.0
@export var x_after_phase2: float = 5132.0

@export var interval_min: float = 0.6
@export var interval_max: float = 1.4

@export var fallback_cam_speed_px_s: float = 60.0   # si tu cámara no tiene go_to_x, usamos esta velocidad
@export var cam_tween_trans := Tween.TRANS_SINE
@export var cam_tween_ease := Tween.EASE_IN_OUT
@export var debug_logs := false

# NUEVO: esperar a que el otro spawner quede vacío antes de arrancar
@export var wait_for_other_spawns := true
@export var groups_to_wait: Array[String] = ["enemy_1", "enemy_2", "enemy_3", "enemy_4"]

var rng := RandomNumberGenerator.new()
var cam: Camera2D
var _spawn_timer: Timer
var _cam_tween: Tween

# Estados
const S_WAIT_START := -1
const S_PHASE1 := 0
const S_WAIT_CLEAR1 := 1
const S_WAIT_CAM1 := 2
const S_PHASE2 := 3
const S_WAIT_CLEAR2 := 4
const S_WAIT_CAM2 := 5
const S_DONE := 6
var state: int = S_WAIT_START

# Contadores por fase
var spawned_this_phase: int = 0
var alive_this_phase: int = 0

func _ready() -> void:
	rng.randomize()

	# Cámara (fallbacks)
	if cam_path != NodePath():
		cam = get_node_or_null(cam_path) as Camera2D
	if cam == null:
		cam = get_tree().get_first_node_in_group("main_camera") as Camera2D
	if cam == null and get_viewport():
		cam = get_viewport().get_camera_2d()

	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = true
	add_child(_spawn_timer)
	_spawn_timer.connect("timeout", Callable(self, "_on_spawn_timer_timeout"))

	set_process(true)

	# Arranque: o esperamos a que el otro spawn quede vacío, o empezamos ya
	if wait_for_other_spawns:
		state = S_WAIT_START
		if debug_logs: print("[Spawner] Esperando a que grupos previos queden vacíos…")
	else:
		state = S_PHASE1
		_reset_phase_counters()
		_arm_next_spawn()
		if debug_logs: print("[Spawner] START directo: FASE 1")

# ---------------- Utilidad: conteo de grupos externos ----------------
func _count_wait_groups_alive() -> int:
	var total := 0
	for g in groups_to_wait:
		var nodes := get_tree().get_nodes_in_group(g)
		# Contamos sólo nodos vivos/instanciados
		for n in nodes:
			if is_instance_valid(n):
				total += 1
	return total

# ---------------- Spawning ----------------
func _arm_next_spawn() -> void:
	if state == S_PHASE1:
		if spawned_this_phase >= phase1_max_spawns:
			_spawn_timer.stop()
			state = S_WAIT_CLEAR1
			if debug_logs: print("[Spawner] F1 done spawning. Waiting clear…")
			return
	elif state == S_PHASE2:
		if spawned_this_phase >= phase2_max_spawns:
			_spawn_timer.stop()
			state = S_WAIT_CLEAR2
			if debug_logs: print("[Spawner] F2 done spawning. Waiting clear…")
			return
	else:
		_spawn_timer.stop()
		return

	_spawn_timer.start(rng.randf_range(interval_min, interval_max))

func _on_spawn_timer_timeout() -> void:
	match state:
		S_PHASE1:
			_spawn_enemy_at(phase1_x_spawn, rng.randf_range(phase1_y_min, phase1_y_max))
			spawned_this_phase += 1
			alive_this_phase += 1
			_arm_next_spawn()
		S_PHASE2:
			_spawn_enemy_at(phase2_x_spawn, rng.randf_range(phase2_y_min, phase2_y_max))
			spawned_this_phase += 1
			alive_this_phase += 1
			_arm_next_spawn()

func _spawn_enemy_at(x: float, y: float) -> void:
	var e = ENEMY.instantiate()
	e.global_position = Vector2(x, y)
	get_parent().add_child(e)

	if e.has_signal("died"):
		if not e.is_connected("died", Callable(self, "_on_enemy_died")):
			e.connect("died", Callable(self, "_on_enemy_died"))
	else:
		if not e.tree_exited.is_connected(Callable(self, "_on_enemy_tree_exited")):
			e.tree_exited.connect(Callable(self, "_on_enemy_tree_exited"))

	if debug_logs:
		print("[Spawner] +spawn (", x, ",", y, ")  phase=", state, " spawned=", spawned_this_phase+1)

func _on_enemy_died() -> void:
	if alive_this_phase > 0:
		alive_this_phase -= 1
	_check_phase_clear()

func _on_enemy_tree_exited() -> void:
	if alive_this_phase > 0:
		alive_this_phase -= 1
	_check_phase_clear()

# --------------- Fases / Cámara ---------------
func _process(_delta: float) -> void:
	match state:
		S_WAIT_START:
			# No empezamos hasta que NO quede nadie de los grupos previos
			if _count_wait_groups_alive() == 0:
				state = S_PHASE1
				_reset_phase_counters()
				_arm_next_spawn()
				if debug_logs: print("[Spawner] Grupos previos vacíos → START FASE 1")

		S_WAIT_CLEAR1:
			if alive_this_phase <= 0:
				_start_camera_move_to(x_after_phase1)
				state = S_WAIT_CAM1
		S_WAIT_CAM1:
			if _camera_reached_x(x_after_phase1):
				state = S_PHASE2
				_reset_phase_counters()
				_arm_next_spawn()
				if debug_logs: print("[Spawner] F1 cleared & camera reached → START F2")
		S_WAIT_CLEAR2:
			if alive_this_phase <= 0:
				_start_camera_move_to(x_after_phase2)
				state = S_WAIT_CAM2
		S_WAIT_CAM2:
			if _camera_reached_x(x_after_phase2):
				state = S_DONE
				if debug_logs: print("[Spawner] F2 cleared & camera reached → DONE")
		_:
			pass

func _check_phase_clear() -> void:
	match state:
		S_PHASE1:
			if spawned_this_phase >= phase1_max_spawns and alive_this_phase <= 0:
				state = S_WAIT_CLEAR1
		S_PHASE2:
			if spawned_this_phase >= phase2_max_spawns and alive_this_phase <= 0:
				state = S_WAIT_CLEAR2

func _reset_phase_counters() -> void:
	spawned_this_phase = 0
	alive_this_phase = 0

# --------------- Movimiento de cámara (lento) ---------------
func _start_camera_move_to(target_x: float) -> void:
	if cam == null:
		return

	# Usa tu cámara si ofrece go_to_x(x) (un argumento, velocidad interna = 60)
	if cam.has_method("go_to_x"):
		cam.call("go_to_x", target_x)
		return

	# Fallback: tween propio a 60 px/s para que sea suave y lento
	if _cam_tween and _cam_tween.is_running():
		_cam_tween.kill()
	var start_x := cam.global_position.x
	var dx = abs(target_x - start_x)
	var dur = dx / max(fallback_cam_speed_px_s, 1.0)

	_cam_tween = create_tween().set_trans(cam_tween_trans).set_ease(cam_tween_ease)
	_cam_tween.tween_property(cam, "global_position:x", target_x, dur)

func _camera_reached_x(target_x: float) -> bool:
	if cam == null:
		return true
	return abs(cam.global_position.x - target_x) <= 0.8
