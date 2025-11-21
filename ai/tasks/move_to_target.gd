extends BTAction

@export var target_var: StringName = &"target"
@export var speed_var = 160
@export var stop_distance = 40.0

func _tick(_delta):
	var target = blackboard.get_var(target_var, null)
	if target == null:
		return FAILURE
	if not (target is Node2D):
		return FAILURE

	var to_target = target.global_position - agent.global_position
	var dist = to_target.length()

	if dist <= stop_distance:
		agent.move(0.0, 0.0)
		return SUCCESS

	var dir_x = sign(to_target.x)
	if dir_x == 0.0:
		dir_x = 1.0

	agent.move(dir_x, speed_var)
	return RUNNING
