extends Area2D  # puede ser Node2D aunque spawnees Area2D
# Qué escena vas a spawnear (cámbialo si necesitas otro prefab)
@export var spawn_scene: PackedScene = preload("res://Scenes/Players/Player 1/Armas_P1/chicken_crazy.tscn")

# Intervalo aleatorio entre spawns
@export var interval_min: float = 0.6
@export var interval_max: float = 1.4

# Zona de aparición (coordenadas de mundo)
@export var x_min: float = 548.0
@export var x_max: float = 5200.0
@export var y_min: float = 300.0
@export var y_max: float = 400.0

# Límite opcional durante la ventana activa (-1 = sin límite)
@export var max_total_in_window: int = -1

# DEBUG
@export var debug_logs := true

var _rng := RandomNumberGenerator.new()
var _timer: Timer
var _active := false
var _end_time := 0.0
var _spawned_this_window := 0

# -------------------------------------------------------------------
# Señales de UI: este spawner escucha "request_spawn(duration: float)"
# desde el panel UI_abilities.
# -------------------------------------------------------------------

func _ready() -> void:
	_rng.randomize()

	# Asegura timer
	_timer = get_node_or_null("spawn_timer") as Timer
	if _timer == null:
		_timer = Timer.new()
		_timer.name = "spawn_timer"
		_timer.one_shot = true
		add_child(_timer)
	if not _timer.is_connected("timeout", Callable(self, "_on_spawn_timer_timeout")):
		_timer.connect("timeout", Callable(self, "_on_spawn_timer_timeout"))

	# Conexión automática con el UI (ajusta la ruta si tu panel está en otro sitio)
	var ui := get_node_or_null("../CanvasLayer/UI_abilities")
	if ui and ui.has_signal("request_spawn") and not ui.is_connected("request_spawn", Callable(self, "start_spawn_for")):
		ui.connect("request_spawn", Callable(self, "start_spawn_for"))
		_log("[Spawner] Conectado a UI_abilities.request_spawn ✅")
	else:
		_log("[Spawner] No encontré UI_abilities o su señal; conecta manualmente si hace falta.")

# Llamado por el UI (o manualmente) para spawnear durante 'seconds'
func start_spawn_for(seconds: float) -> void:
	if seconds <= 0.0:
		_log("[Spawner] start_spawn_for: duración inválida.")
		return
	if spawn_scene == null:
		_log("[Spawner] start_spawn_for: spawn_scene es null.")
		return

	_active = true
	_end_time = Time.get_unix_time_from_system() + seconds
	_spawned_this_window = 0
	_logf("[Spawner] 🟢 Activado por %s s", [String.num(seconds, 2)])
	_schedule_next()

func stop_spawn() -> void:
	if not _active:
		return
	_active = false
	if _timer:
		_timer.stop()
	_log("[Spawner] 🔴 Desactivado")

func _on_spawn_timer_timeout() -> void:
	if not _active:
		return

	# ¿Se acabó la ventana de tiempo?
	if Time.get_unix_time_from_system() >= _end_time:
		_log("[Spawner] ⌛ Ventana terminada.")
		stop_spawn()
		return

	# ¿Se alcanzó el límite de spawns en esta ventana?
	if max_total_in_window >= 0 and _spawned_this_window >= max_total_in_window:
		_log("[Spawner] Límite de spawns alcanzado en la ventana.")
		stop_spawn()
		return

	# Instanciar y posicionar
	var inst := spawn_scene.instantiate()
	if inst == null:
		_log("[Spawner] ERROR: no pude instanciar la escena.")
		stop_spawn()
		return

	var px := _rng.randf_range(x_min, x_max)
	var py := _rng.randf_range(y_min, y_max)
	get_parent().add_child(inst)
	inst.global_position = Vector2(px, py)

	_spawned_this_window += 1
	_logf("[Spawner] Spawned #%s en (%.1f, %.1f)", [str(_spawned_this_window), px, py])

	# Planificar el siguiente
	_schedule_next()

func _schedule_next() -> void:
	var delay := _rng.randf_range(interval_min, interval_max)
	if delay < 0.02:
		delay = 0.02
	if _timer:
		_timer.start(delay)
	_logf("[Spawner] Próximo en %s s", [String.num(delay, 2)])

# -----------------------
# Utilidades de logging
# -----------------------
func _log(msg: String) -> void:
	if debug_logs:
		print(msg)

func _logf(fmt: String, params: Array = []) -> void:
	if debug_logs:
		print(fmt % params)
