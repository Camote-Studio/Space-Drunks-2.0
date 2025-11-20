extends BTAction

@export var target_var: StringName = &"target"
@export var attack_range: float = 80.0

var started: bool = false

func _tick(_delta: float) -> Status:
	var target: CharacterBody2D = blackboard.get_var(target_var)
	if target == null:
		started = false
		return FAILURE
	
	var dx = target.global_position.x - agent.global_position.x
	if not started and abs(dx) > attack_range:
		return FAILURE
	
	if not started:
		agent.start_attack()
		started = true
		return RUNNING
	
	if agent.is_using_ability():
		return RUNNING
	
	started = false
	return SUCCESS
