extends BTAction

@export var range_min_in_range: float = 100.0
@export var range_max_in_range: float = 150.0

@export var position_var: StringName = &"pos"
@export var dir_var: StringName = &"dir"

func _tick(_delta: float) -> Status:
	var pos: Vector2
	var dir = random_dir()
	
	pos = random_pos(dir)
	blackboard.set_var(position_var, pos)
	
	print(dir, "     ", pos.x, " age_pos ", agent.global_position.x)
	return SUCCESS
	
func random_pos(dir):
	var vector: Vector2
	var distance = randi_range(range_min_in_range, range_max_in_range)* dir
	var final_position = (distance + agent.global_position.x)
	vector.x = final_position
	return vector
	
func random_dir():
	var dir = randi_range(-2,1)
	if abs(dir) != dir:
		dir = -1
	else:
		dir = 1
	blackboard.set_var(dir_var, dir)
	return dir
	
