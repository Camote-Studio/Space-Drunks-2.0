extends BTAction

@export var target_var: StringName = &"target"

func _tick(_delta):
	var players = agent.get_tree().get_nodes_in_group("players")
	if players.size() == 0:
		return FAILURE

	var closest = null
	var best_dist = INF

	for p in players:
		if p is Node2D:
			var d = agent.global_position.distance_to(p.global_position)
			if d < best_dist:
				best_dist = d
				closest = p

	if closest == null:
		return FAILURE

	blackboard.set_var(target_var, closest)
	return SUCCESS
