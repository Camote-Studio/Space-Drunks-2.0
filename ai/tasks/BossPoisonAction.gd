extends BTAction

func _tick(_delta: float) -> Status:
	agent.start_poison()
	return SUCCESS
