extends Area2D

# Cambia esta ruta si tu escena del enemigo 4 está en otra carpeta
const ENEMY4 = preload("res://Scenes/enemie_4.tscn")

@export var cam_path: NodePath
@export var spawn_offset_x: float = 560.0  # distancia delante de la cámara

# --------- FASE 1 ---------
@export var phase1_max_spawns: int = 3
@export var phase1_y_min: float = 330.0
@export var phase1_y_max: float = 480.0
@export var x_after_phase1: float = 2999.0

# --------- FASE 2 ---------
@export var phase2_max_spawns: int = 3
@export var phase2_y_min: float = 204.0
@export var phase2_y_max: float = 482.0
@export var x_after_phase2: float = 5132.0

# Intervalo entre spawns dentro de cada fase
@export var interval_min: float = 0.6
@export var interval_max: float = 1.0

# Estados
enum { S_PHASE1, S_WAIT_CLEAR1, S_WAIT_CAM1, S_PHASE2, S_WAIT_CLEAR2, S_DONE }

var rng := RandomNumberGenerator.new()
var cam: Camera2D
var state := S_PHASE1
var spawned := 0
var _timer: Timer
var _cam_has_signal := false

func _enter_tree() -> void:
	# Antiduplicado: solo 1 spawner activo en el árbol
	if get_tree().has_meta("enemy4_phase_spawner_master"):
		queue_free()
	else:
		get_tree().set_meta("enemy4_phase_spawner_master", self)

func _exit_tree() -> void:
	if get_tree().get_meta("enemy4_phase_spawner_master") == self:
		get_tree().set_meta("enemy4_phase_spawner_master", null)

func _ready() -> void:
	rng.randomize()

	# Cámara
	cam = get_node_or_null(cam_path) as Camera2D
	if cam == null:
		cam = get_tree().get_first_node_in_group("main_camera") as Camera2D

	# Señal de cámara
	if cam and not cam.is_connected("reached_target", Callable(self, "_on_cam_reached")):
		_cam_has_signal = cam.connect("reached_target", Callable(self, "_on_cam_reached")) == OK
	else:
		_cam_has_signal = true

	# Timer
	_timer = $spawn_timer if has_node("spawn_timer") else null
	if _timer == null:
		_timer = Timer.new()
		_timer.name = "spawn_timer"
		add_child(_timer)
	_timer.one_shot = true
	if not _timer.is_connected("timeout", Callable(self, "_on_spawn_timer_timeout")):
		_timer.connect("timeout", Callable(self, "_on_spawn_timer_timeout"))

	# Arrancamos Fase 1
	state = S_PHASE1
	spawned = 0
	_timer.start(rng.randf_range(interval_min, interval_max))

	set_process(true)

func _on_spawn_timer_timeout() -> void:
	match state:
		S_PHASE1:
			if spawned >= phase1_max_spawns:
				state = S_WAIT_CLEAR1
				return
			_spawn_one(phase1_y_min, phase1_y_max)
			spawned += 1
			_timer.start(rng.randf_range(interval_min, interval_max))

		S_PHASE2:
			if spawned >= phase2_max_spawns:
				state = S_WAIT_CLEAR2
				return
			_spawn_one(phase2_y_min, phase2_y_max)
			spawned += 1
			_timer.start(rng.randf_range(interval_min, interval_max))

		_:
			pass

func _process(_dt: float) -> void:
	match state:
		S_WAIT_CLEAR1:
			if _alive_enemy4() == 0 and cam:
				# Mover cámara a x_after_phase1
				if cam.has_method("go_to_x"):
					cam.go_to_x(x_after_phase1)
				else:
					cam.set("target_x", x_after_phase1)
					cam.set("moving", true)
				state = S_WAIT_CAM1

		S_WAIT_CAM1:
			if not _cam_has_signal and cam:
				var moving := false
				if cam.has_method("is_moving"):
					moving = cam.is_moving()
				elif cam.has_method("get"):
					moving = cam.get("moving")
				if not moving and abs(cam.global_position.x - x_after_phase1) < 1.0:
					_start_phase2()

		S_WAIT_CLEAR2:
			if _alive_enemy4() == 0 and cam:
				# Mover cámara a x_after_phase2
				if cam.has_method("go_to_x"):
					cam.go_to_x(x_after_phase2)
				else:
					cam.set("target_x", x_after_phase2)
					cam.set("moving", true)
				state = S_DONE

		S_DONE:
			pass

func _on_cam_reached(x: float) -> void:
	if state == S_WAIT_CAM1 and abs(x - x_after_phase1) < 1.0:
		_start_phase2()

func _start_phase2() -> void:
	state = S_PHASE2
	spawned = 0
	_timer.start(rng.randf_range(interval_min, interval_max))

func _spawn_one(y_min: float, y_max: float) -> void:
	if cam == null:
		return
	var e = ENEMY4.instantiate()
	var y := rng.randf_range(y_min, y_max)
	# Spawn relativo a la cámara (más cerca de la acción)
	var x := cam.global_position.x + spawn_offset_x
	e.global_position = Vector2(x, y)
	get_parent().add_child(e)

func _alive_enemy4() -> int:
	return get_tree().get_nodes_in_group("enemy_4").size()
