extends Area2D

const ENEMY = preload("res://Scenes/Enemies/enemie_2.tscn")

@export var x_min: float = 73.0
@export var x_max: float = 2590.0
@export var y_min: float = 204.0
@export var y_max: float = 482.0

@export var batch_min: int = 1
@export var batch_max: int = 3
@export var interval_min: float = 1.2
@export var interval_max: float = 2.8
@export var concurrent_cap: int = 8
@export var total_cap: int = -1
@export var wave_spread: float = 0.8
@export var move_camera_on_clear: bool = false
@export var cam_path: NodePath
@export var camera_target_x: float = 2999.0

var spawned_total: int = 0
var rng := RandomNumberGenerator.new()
var cam: Camera2D
var moved: bool = false

func _ready() -> void:
	rng.randomize()
	cam = get_node_or_null(cam_path) as Camera2D
	if cam == null:
		cam = get_tree().get_first_node_in_group("main_camera") as Camera2D
	$spawn_timer.start(rng.randf_range(interval_min, interval_max))
	set_process(true)

func _on_spawn_timer_timeout() -> void:
	if total_cap >= 0 and spawned_total >= total_cap:
		$spawn_timer.stop()
		return
	var alive := get_tree().get_nodes_in_group("enemy_2").size()
	var free_slots := concurrent_cap - alive
	if free_slots <= 0:
		$spawn_timer.start(rng.randf_range(interval_min * 0.6, interval_min))
		return
	var n := rng.randi_range(batch_min, batch_max)
	if total_cap >= 0:
		var remaining := total_cap - spawned_total
		n = min(n, remaining)
	n = clamp(n, 1, max(1, free_slots))
	for i in n:
		var delay := rng.randf_range(0.0, wave_spread)
		_spawn_delayed(delay)
	$spawn_timer.start(rng.randf_range(interval_min, interval_max))

func _spawn_delayed(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if total_cap >= 0 and spawned_total >= total_cap:
		return
	var alive := get_tree().get_nodes_in_group("enemy_2").size()
	if alive >= concurrent_cap:
		return
	var e = ENEMY.instantiate()
	var x := rng.randf_range(x_min, x_max)
	var y := rng.randf_range(y_min, y_max)
	e.global_position = Vector2(x, y)
	get_parent().add_child(e)
	spawned_total += 1

func _process(delta: float) -> void:
	if not move_camera_on_clear or moved:
		return
	if total_cap < 0:
		return
	if spawned_total < total_cap:
		return
	var alive := get_tree().get_nodes_in_group("enemy_2").size()
	if alive == 0 and cam:
		if cam.has_method("go_to_x"):
			cam.go_to_x(camera_target_x)
		else:
			cam.set("target_x", camera_target_x)
			cam.set("moving", true)
		moved = true
