extends Area2D

# =============================================================================
# CONSTANTES Y RECURSOS
# =============================================================================

const ENEMY: PackedScene = preload("res://Scenes/Enemies/enemie_2.tscn")

# =============================================================================
# VARIABLES EXPORTADAS - CONFIGURACIÓN
# =============================================================================

@export var cam_path: NodePath

# Límites de spawn
@export var y_min: float = 280.0
@export var y_max: float = 482.0
@export var spawn_margin: float = 100.0     # píxeles fuera del viewport

# Configuración de oleadas
@export var wave_spread: float = 0.7        # retraso aleatorio entre spawns
@export var concurrent_cap: int = 8         # enemigos vivos (reducido para evitar amontonamiento)
@export var batch_size: int = 2             # enemigos por batch (reducido)

# Configuración de movimiento de cámara
@export var camera_movement_threshold: float = 5.0  # movimiento mínimo para activar spawn

# =============================================================================
# VARIABLES DE ESTADO
# =============================================================================

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var cam: Camera2D
var last_cam_x: float = 0.0

var wave_active: bool = false
var inflight_scheduled: int = 0
var alive_total: int = 0
var enemies_dead: int = 0
var _scheduling: bool = false

# Variables para control de spawn inteligente
var _spawn_cooldown_timer: float = 0.0
var _last_spawn_time: float = 0.0
var _min_spawn_interval: float = 0.5

# =============================================================================
# INICIALIZACIÓN
# =============================================================================

func _ready() -> void:
	_initialize_rng()
	_setup_camera_reference()
	_setup_process()

func _initialize_rng() -> void:
	rng.randomize()

func _setup_camera_reference() -> void:
	cam = get_node_or_null(cam_path) as Camera2D
	if cam == null:
		cam = get_tree().get_first_node_in_group("main_camera") as Camera2D
	if cam:
		last_cam_x = cam.global_position.x

func _setup_process() -> void:
	set_process(true)

# =============================================================================
# LÓGICA PRINCIPAL
# =============================================================================

func _process(delta: float) -> void:
	if cam == null:
		return
	
	_update_spawn_cooldown(delta)
	_update_wave_state()
	_handle_continuous_spawn()

func _update_spawn_cooldown(delta: float) -> void:
	if _spawn_cooldown_timer > 0.0:
		_spawn_cooldown_timer -= delta

func _update_wave_state() -> void:
	var cam_movement = abs(cam.global_position.x - last_cam_x)
	var cam_moving: bool = cam_movement > camera_movement_threshold
	
	# Activar spawn solo si la cámara se mueve significativamente
	wave_active = cam_moving
	last_cam_x = cam.global_position.x

func _handle_continuous_spawn() -> void:
	if wave_active and not _scheduling and _can_spawn_now():
		_try_spawn_next_batch()

func _can_spawn_now() -> bool:
	var current_time = Time.get_time_dict_from_system()["second"]
	var time_since_last_spawn = current_time - _last_spawn_time
	
	return _spawn_cooldown_timer <= 0.0 and time_since_last_spawn >= _min_spawn_interval

# =============================================================================
# SISTEMA DE SPAWN
# =============================================================================

func _try_spawn_next_batch() -> void:
	if not wave_active:
		return
	
	var free_slots: int = concurrent_cap - (alive_total + inflight_scheduled)
	if free_slots <= 0:
		return
	
	# Ajustar el tamaño del batch según los slots libres y la situación actual
	var adjusted_batch_size = _calculate_optimal_batch_size(free_slots)
	var to_spawn: int = min(adjusted_batch_size, free_slots)
	
	if to_spawn <= 0:
		return
	
	_scheduling = true
	_last_spawn_time = Time.get_time_dict_from_system()["second"]
	
	for i in range(to_spawn):
		var delay: float = rng.randf_range(0.0, wave_spread * 1.5)  # Mayor separación temporal
		inflight_scheduled += 1
		_spawn_delayed(delay)
	
	_scheduling = false
	_spawn_cooldown_timer = _min_spawn_interval

func _calculate_optimal_batch_size(free_slots: int) -> int:
	# Spawns más pequeños si hay muchos enemigos vivos
	if alive_total >= concurrent_cap * 0.7:  # Si hay 70% o más enemigos vivos
		return 1
	elif alive_total >= concurrent_cap * 0.5:  # Si hay 50% o más
		return min(2, batch_size)
	else:
		return batch_size

func _spawn_delayed(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	inflight_scheduled = max(0, inflight_scheduled - 1)
	
	if not wave_active or alive_total >= concurrent_cap:
		return
	
	var spawn_pos: Vector2 = _get_valid_spawn_position()
	if spawn_pos == Vector2.ZERO:
		return
	
	_create_and_setup_enemy(spawn_pos)

func _create_and_setup_enemy(spawn_pos: Vector2) -> void:
	var enemy_instance: Node2D = ENEMY.instantiate() as Node2D
	if enemy_instance == null:
		print("Error: No se pudo instanciar el enemigo")
		return
	
	enemy_instance.global_position = spawn_pos
	get_parent().add_child(enemy_instance)
	alive_total += 1
	
	_connect_enemy_signals(enemy_instance)
	
	# Pequeña variación en las estadísticas para diversidad
	_apply_enemy_variations(enemy_instance)

func _connect_enemy_signals(enemy: Node2D) -> void:
	# Priorizar señal 'died' si existe
	if enemy.has_signal("died") and not enemy.is_connected("died", Callable(self, "_on_enemy_died")):
		enemy.connect("died", Callable(self, "_on_enemy_died"))
	# Fallback a tree_exited
	elif not enemy.tree_exited.is_connected(Callable(self, "_on_enemy_tree_exited")):
		enemy.tree_exited.connect(Callable(self, "_on_enemy_tree_exited"))

func _apply_enemy_variations(enemy: Node2D) -> void:
	# Pequeñas variaciones en velocidad y comportamiento para evitar movimientos idénticos
	if enemy.has_method("set") and enemy.has_property("speed"):
		var speed_variation = rng.randf_range(0.85, 1.15)  # ±15% variación
		enemy.speed *= speed_variation
	
	# Variación en el seed de movimiento ondulante para mayor naturalidad
	if enemy.has_property("walk_seed"):
		enemy.walk_seed = rng.randf() * TAU

# =============================================================================
# SISTEMA DE POSICIONAMIENTO
# =============================================================================

func _get_valid_spawn_position(max_tries: int = 30) -> Vector2:
	if cam == null:
		return Vector2.ZERO
	
	var camera_bounds = _calculate_camera_bounds()
	
	for i in range(max_tries):
		var potential_position = _generate_spawn_position(camera_bounds)
		
		if _is_position_valid(potential_position, camera_bounds):
			return potential_position
	
	# Fallback con posición garantizada
	return _get_fallback_spawn_position(camera_bounds)

func _calculate_camera_bounds() -> Dictionary:
	var screen_rect: Rect2 = get_viewport().get_visible_rect()
	var half_size: Vector2 = screen_rect.size * 0.5 * cam.zoom
	var cam_center: Vector2 = cam.global_position
	var cam_rect: Rect2 = Rect2(cam_center - half_size, screen_rect.size * cam.zoom)
	
	return {
		"rect": cam_rect,
		"center": cam_center,
		"half_size": half_size
	}

func _generate_spawn_position(camera_bounds: Dictionary) -> Vector2:
	var cam_rect = camera_bounds.rect
	
	# Lado aleatorio: -1 = izquierda, 1 = derecha
	var side: int = rng.randi_range(0, 1) * 2 - 1
	var spawn_distance = rng.randf_range(spawn_margin, spawn_margin + 200)
	
	var x: float = 0.0
	if side == -1:
		x = cam_rect.position.x - spawn_distance
	else:
		x = cam_rect.position.x + cam_rect.size.x + spawn_distance
	
	var y: float = rng.randf_range(y_min, y_max)
	return Vector2(x, y)

func _is_position_valid(pos: Vector2, camera_bounds: Dictionary) -> bool:
	var cam_rect = camera_bounds.rect
	
	# Debe estar fuera de la pantalla
	if cam_rect.has_point(pos):
		return false
	
	# Verificar que no esté demasiado cerca de otros enemigos
	return _is_position_clear_of_enemies(pos)

func _is_position_clear_of_enemies(pos: Vector2, min_distance: float = 80.0) -> bool:
	var enemies = get_tree().get_nodes_in_group("enemy_2")
	
	for enemy in enemies:
		if enemy and enemy.has_method("global_position"):
			var distance = pos.distance_to(enemy.global_position)
			if distance < min_distance:
				return false
	
	return true

func _get_fallback_spawn_position(camera_bounds: Dictionary) -> Vector2:
	var cam_rect = camera_bounds.rect
	var side: int = rng.randi_range(0, 1) * 2 - 1
	
	var x: float = cam_rect.position.x - spawn_margin if side == -1 else cam_rect.position.x + cam_rect.size.x + spawn_margin
	var y: float = rng.randf_range(y_min, y_max)
	
	return Vector2(x, y)

# =============================================================================
# MANEJO DE EVENTOS DE ENEMIGOS
# =============================================================================

func _on_enemy_died() -> void:
	alive_total = max(0, alive_total - 1)
	enemies_dead += 1
	
	# Debug opcional
	if enemies_dead % 10 == 0:
		print("Enemigos eliminados: ", enemies_dead, " | Vivos: ", alive_total)

func _on_enemy_tree_exited() -> void:
	alive_total = max(0, alive_total - 1)

# =============================================================================
# MÉTODOS DE UTILIDAD Y DEBUG
# =============================================================================

func get_spawn_info() -> Dictionary:
	return {
		"alive_total": alive_total,
		"enemies_dead": enemies_dead,
		"inflight_scheduled": inflight_scheduled,
		"wave_active": wave_active,
		"concurrent_cap": concurrent_cap
	}

func force_spawn_batch(count: int = 1) -> void:
	"""Método para forzar spawn manual (útil para testing)"""
	var old_cap = concurrent_cap
	concurrent_cap += count
	_try_spawn_next_batch()
	await get_tree().create_timer(1.0).timeout
	concurrent_cap = old_cap

func clear_all_enemies() -> void:
	"""Elimina todos los enemigos activos"""
	var enemies = get_tree().get_nodes_in_group("enemy_2")
	for enemy in enemies:
		if enemy and enemy.has_method("queue_free"):
			enemy.queue_free()
	alive_total = 0
	inflight_scheduled = 0
