extends Camera2D
@export var pan_speed: float = 100.0 
var _x_goal: float = 2057

func go_to_x(x_goal: float) -> void:
	make_current()
	_x_goal = x_goal

func _physics_process(delta: float) -> void:
	if _x_goal != INF:
		var pos := global_position
		pos.x = move_toward(pos.x, _x_goal, pan_speed * delta) # mantiene Y
		global_position = pos
		if abs(pos.x - _x_goal) < 0.5:
			_x_goal = INF
