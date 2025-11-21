extends BTAction

@export var target_pos_var: StringName = &"pos"
@export var dir_var: StringName = &"dir"

@export var speed_var = 140
@export var tolerance = 8.0

func _tick(_delta):
	var target_pos = blackboard.get_var(target_pos_var, Vector2.ZERO)
	var dir = blackboard.get_var(dir_var, 1.0)

	var dx = target_pos.x - agent.global_position.x
	var dist = abs(dx)

	if dist <= tolerance:
		agent.move(0.0, 0.0)
		return SUCCESS

	agent.move(dir, speed_var)
	return RUNNING
