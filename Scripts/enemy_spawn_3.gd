extends Area2D

const ENEMY = preload("res://Scenes/Enemies/enemie_3.tscn")

@export var cam_path: NodePath

@export var x_min: float = 73.0
@export var x_max: float = 2590.0
@export var y_min: float = 366.0
@export var y_max: float = 482.0

@export var batch_size: int = 3        # cantidad de enemigos por lote
@export var wave_spread: float = 0.5   # dispersión del spawn en segundos
@export var concurrent_cap: int = 8    # máximo de enemigos vivos

var rng := RandomNumberGenerator.new()
var cam: Camera2D
var wave_active := false
var current_batch_id := 0
var batch_alive := 0
var inflight_scheduled := 0
var alive_total := 0
var _scheduling := false

func _ready() -> void:
	rng.randomize()
	cam = get_node_or_null(cam_path) as Camera2D
	if cam == null:
		cam = get_tree().get_first_node_in_group("main_camera") as Camera2D
	
	_start_wave()  # ⚡ Inicia las oleadas inmediatamente
	set_process(true)

func _process(_delta: float) -> void:
	if wave_active and batch_alive == 0 and inflight_scheduled == 0 and not _scheduling:
		_try_spawn_next_batch()

func _start_wave() -> void:
	wave_active = true
	current_batch_id = 0
	batch_alive = 0
	inflight_scheduled = 0

func _stop_wave() -> void:
	wave_active = false
	batch_alive = 0
	inflight_scheduled = 0

func _try_spawn_next_batch() -> void:
	if not wave_active:
		return
	
	var free_slots := concurrent_cap - (alive_total + inflight_scheduled)
	if free_slots <= 0:
		return
	
	var to_spawn = min(batch_size, max(0, free_slots))
	if to_spawn <= 0:
		return
	
	current_batch_id += 1
	_scheduling = true
	
	for i in range(to_spawn):
		var delay := rng.randf_range(0.0, wave_spread)
		inflight_scheduled += 1
		_spawn_delayed(delay, current_batch_id)
	
	_scheduling = false

func _spawn_delayed(delay: float, batch_id: int) -> void:
	await get_tree().create_timer(delay).timeout
	inflight_scheduled = max(0, inflight_scheduled - 1)
	
	if not wave_active:
		return
	
	if alive_total >= concurrent_cap:
		return
	
	var e = ENEMY.instantiate()
	
	var x := rng.randf_range(x_min, x_max)
	var y := rng.randf_range(y_min, y_max)
	
	# ⚡ Aseguramos que NO aparezca dentro de la cámara
	if cam:
		var cam_rect := Rect2(
			cam.global_position - cam.get_viewport_rect().size * 0.5,
			cam.get_viewport_rect().size
		)
		while cam_rect.has_point(Vector2(x, y)):
			x = rng.randf_range(x_min, x_max)
			y = rng.randf_range(y_min, y_max)
	
	e.global_position = Vector2(x, y)
	get_parent().add_child(e)
	
	alive_total += 1
	batch_alive += 1
	
	if e.has_signal("died"):
		if not e.is_connected("died", Callable(self, "_on_enemy_died")):
			e.connect("died", Callable(self, "_on_enemy_died").bind(batch_id))
	else:
		if not e.tree_exited.is_connected(Callable(self, "_on_enemy_tree_exited")):
			e.tree_exited.connect(Callable(self, "_on_enemy_tree_exited"))

func _on_enemy_died(batch_id: int) -> void:
	alive_total = max(0, alive_total - 1)
	if batch_id == current_batch_id:
		batch_alive = max(0, batch_alive - 1)

func _on_enemy_tree_exited() -> void:
	alive_total = max(0, alive_total - 1)
	batch_alive = max(0, batch_alive - 1)
