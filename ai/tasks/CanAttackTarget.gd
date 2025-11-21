extends BTAction

@export var target_var: StringName = &"target"
@export var attack_range: float = 50.0

func _tick(_delta: float) -> Status:
	var target: CharacterBody2D = blackboard.get_var(target_var)
	if target == null:
		return FAILURE
	var dx = target.global_position.x - agent.global_position.x
	if abs(dx) <= attack_range:
		return SUCCESS
	return FAILURE
