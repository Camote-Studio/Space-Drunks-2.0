extends Area2D

const ENEMY = preload("res://Scenes/Enemies/enemie_1.tscn")

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

var rng := RandomNumberGenerator.new()
var cam: Camera2D
var state: int = 0
var spawned: int = 0

const S_PHASE1 := 0
const S_WAIT_CLEAR1 := 1
const S_WAIT_CAM1 := 2
const S_PHASE2 := 3
const S_WAIT_CLEAR2 := 4
const S_DONE := 5

func _ready() -> void:
	rng.randomize()
	cam = get_node_or_null(cam_path) as Camera2D
	if cam == null:
		cam = get_tree().get_first_node_in_group("main_camera") as Camera2D
	if cam and not cam.is_connected("reached_target", Callable(self, "_on_cam_reached")):
		cam.connect("reached_target", Callable(self, "_on_cam_reached"))
	state = S_PHASE1
	spawned = 0
	$spawn_timer.start(rng.randf_range(interval_min, interval_max))
	set_process(true)

func _on_spawn_timer_timeout() -> void:
	if state == S_PHASE1:
		if spawned >= phase1_max_spawns:
			$spawn_timer.stop()
			state = S_WAIT_CLEAR1
			return
		var e1 = ENEMY.instantiate()
		var y1 := rng.randf_range(phase1_y_min, phase1_y_max)
		e1.global_position = Vector2(phase1_x_spawn, y1)
		get_parent().add_child(e1)
		spawned += 1
		$spawn_timer.start(rng.randf_range(interval_min, interval_max))
	elif state == S_PHASE2:
		if spawned >= phase2_max_spawns:
			$spawn_timer.stop()
			state = S_WAIT_CLEAR2
			return
		var e2 = ENEMY.instantiate()
		var y2 := rng.randf_range(phase2_y_min, phase2_y_max)
		e2.global_position = Vector2(phase2_x_spawn, y2)
		get_parent().add_child(e2)
		spawned += 1
		$spawn_timer.start(rng.randf_range(interval_min, interval_max))

func _process(_delta: float) -> void:
	if state == S_WAIT_CLEAR1:
		var alive1 := get_tree().get_nodes_in_group("enemy_1").size()
		if alive1 == 0 and cam:
			if cam.has_method("go_to_x"):
				cam.go_to_x(x_after_phase1)
			else:
				cam.set("target_x", x_after_phase1)
				cam.set("moving", true)
			state = S_WAIT_CAM1
	elif state == S_WAIT_CLEAR2:
		var alive2 := get_tree().get_nodes_in_group("enemy_1").size()
		if alive2 == 0 and cam:
			if cam.has_method("go_to_x"):
				cam.go_to_x(x_after_phase2)
			else:
				cam.set("target_x", x_after_phase2)
				cam.set("moving", true)
			state = S_DONE

func _on_cam_reached(x: float) -> void:
	if state == S_WAIT_CAM1 and abs(x - x_after_phase1) < 1.0:
		state = S_PHASE2
		spawned = 0
		$spawn_timer.start(rng.randf_range(interval_min, interval_max))
