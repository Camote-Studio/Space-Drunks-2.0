extends BTAction

@export var target_var: StringName = &"target"
@export var attack_range = 120.0

func _tick(_delta):
	var target = blackboard.get_var(target_var)
	if target == null:
		return FAILURE

	if not (target is Node2D):
		return FAILURE

	var d = agent.global_position.distance_to(target.global_position)
	if d <= attack_range:
		return SUCCESS

	return FAILURE
