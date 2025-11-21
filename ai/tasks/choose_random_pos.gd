extends BTAction

@export var range_min_in_range = 220.0
@export var range_max_in_range = 380.0

@export var position_var: StringName = &"pos"
@export var dir_var: StringName = &"dir"

func _tick(_delta):
	var dir = random_dir()
	var pos = random_pos(dir)

	blackboard.set_var(position_var, pos)
	blackboard.set_var(dir_var, dir)

	return SUCCESS

func random_pos(dir):
	var distance = randi_range(range_min_in_range, range_max_in_range) * dir
	var final_x = agent.global_position.x + distance
	return Vector2(final_x, agent.global_position.y)

func random_dir():
	var value = randi_range(0, 1)
	var dir = 1.0
	if value == 0:
		dir = -1.0
	return dir
