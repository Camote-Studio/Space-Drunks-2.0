extends BTAction

var started = false

func _tick(_delta):
	if not started:
		agent.start_shout()
		started = true
		return RUNNING

	if agent.is_using_ability():
		return RUNNING

	started = false
	return SUCCESS
