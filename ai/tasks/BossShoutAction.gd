extends BTAction

var started: bool = false

func _tick(_delta: float) -> Status:
	if not started:
		agent.start_shout()
		started = true
		return RUNNING
	
	if agent.is_using_ability():
		return RUNNING
	
	started = false
	return SUCCESS
