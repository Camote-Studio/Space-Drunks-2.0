extends Area2D

# Escenas de enemigos
const ENEMY = preload("res://Scenes/Enemies/Enemigo_CuerpoaCuerpo/Enemy_Pato.tscn")   # principal
const ENEMY2 = preload("res://Scenes/Enemies/Enemigo_CuerpoaCuerpo/Enemy_SuperPato.tscn")          # secundario


@export var cam_path: NodePath

# Límites verticales de spawn
@export var y_min: float = 280.0
@export var y_max: float = 482.0

# Configuración de oleadas
@export var wave_spread: float = 0.3   # retraso aleatorio entre spawns
@export var spawn_margin: float = 30.0 # píxeles fuera del viewport

# Posiciones de fases
@export var phase_positions: Array = [1300.0, 2999.0, 5132.0]

# --- Control de probabilidades y límites ---
@export var enemy2_chance: float = 0.4    # 40% probabilidad
@export var max_enemy1: int = 5           # máximo principales vivos
@export var max_enemy2: int = 3           # máximo secundarios vivos

var rng := RandomNumberGenerator.new()
var cam: Camera2D
var last_cam_x := 0.0

var wave_active := false
var current_phase := 0

# Contadores vivos
var alive_enemy1 := 0
var alive_enemy2 := 0

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

	if cam_moving and not wave_active and current_phase < phase_positions.size():
		_start_wave()
	elif not cam_moving and wave_active:
		_stop_wave()

	if wave_active:
		_try_spawn_enemy()

	if current_phase < phase_positions.size() and cam.global_position.x >= phase_positions[current_phase]:
		if wave_active:
			_stop_wave()
		current_phase += 1

	last_cam_x = cam.global_position.x

# --- Oleadas ---
func _start_wave() -> void:
	wave_active = true
	print("Oleada iniciada")

func _stop_wave() -> void:
	wave_active = false
	print("Oleada detenida")

# --- Intento de spawn ---
func _try_spawn_enemy() -> void:
	# Verificar si aún hay espacio para spawnear
	if alive_enemy1 >= max_enemy1 and alive_enemy2 >= max_enemy2:
		return

	var delay := rng.randf_range(0.0, wave_spread)
	_spawn_delayed(delay)

func _spawn_delayed(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if not wave_active:
		return

	var spawn_pos := _get_valid_spawn_position()
	if spawn_pos == Vector2.ZERO:
		return

	# Decidir si spawn principal o secundario
	var enemy_scene
	var is_enemy2 := false

	if rng.randf() < enemy2_chance and alive_enemy2 < max_enemy2:
		enemy_scene = ENEMY2
		is_enemy2 = true
	elif alive_enemy1 < max_enemy1:
		enemy_scene = ENEMY
	else:
		return  # no hay espacio para ninguno

	var e = enemy_scene.instantiate()
	e.global_position = spawn_pos
	get_parent().add_child(e)

	if is_enemy2:
		alive_enemy2 += 1
	else:
		alive_enemy1 += 1

	# Conectar señales
	if e.has_signal("died"):
		e.connect("died", Callable(self, "_on_enemy_died").bind(is_enemy2))
	else:
		e.tree_exited.connect(Callable(self, "_on_enemy_exited").bind(is_enemy2))

# --- Posición de spawn ---
func _get_valid_spawn_position(max_tries: int = 30) -> Vector2:
	if cam == null:
		return Vector2.ZERO

	var screen_rect := get_viewport().get_visible_rect()
	var half_size := screen_rect.size * 0.5 * cam.zoom
	var cam_center := cam.global_position
	var cam_rect := Rect2(cam_center - half_size, screen_rect.size * cam.zoom)

	for i in range(max_tries):
		var side := rng.randi_range(0, 1) * 2 - 1
		var x := cam_rect.position.x - spawn_margin if side == -1 else cam_rect.position.x + cam_rect.size.x + spawn_margin
		var y := rng.randf_range(y_min, y_max)
		var pos := Vector2(x, y)
		if not cam_rect.has_point(pos):
			return pos

	return Vector2.ZERO

# --- Eventos ---
func _on_enemy_died(is_enemy2: bool) -> void:
	if is_enemy2:
		alive_enemy2 = max(0, alive_enemy2 - 1)
	else:
		alive_enemy1 = max(0, alive_enemy1 - 1)

func _on_enemy_exited(is_enemy2: bool) -> void:
	if is_enemy2:
		alive_enemy2 = max(0, alive_enemy2 - 1)
	else:
		alive_enemy1 = max(0, alive_enemy1 - 1)
