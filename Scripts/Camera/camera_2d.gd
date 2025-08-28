extends Camera2D

signal reached_target(x: float)

@export var speed: float = 30.0
var target_x: float = 0.0
var moving: bool = false

func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 4.0
	make_current()
	add_to_group("main_camera")

func _process(delta: float) -> void:
	if not moving: return
	global_position.x = move_toward(global_position.x, target_x, speed * delta)
	if is_equal_approx(global_position.x, target_x):
		moving = false
		emit_signal("reached_target", target_x)

func go_to_x(x: float) -> void:
	target_x = x
	moving = true
	$"../AnimationPlayer".play("arrow_go")
