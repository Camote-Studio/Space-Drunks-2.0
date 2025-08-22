extends Camera2D

@export var speed: float = 60.0
@export var target_x: float = 1154.0
var moving: bool = true

func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 4.0

func _process(delta: float) -> void:
	if not moving: return
	global_position.x = move_toward(global_position.x, target_x, speed * delta)
	if is_equal_approx(global_position.x, target_x):
		moving = false
