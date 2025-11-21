@tool
extends BTAction

@export var dash_speed = 1200.0
@export var duration = 0.20
@export var target_var: StringName = &"target"

var _impulse_applied = false

func _generate_name() -> String:
	return "BossDashImpulseToTarget dash: %s dur: %ss" % [dash_speed, duration]

func _enter() -> void:
	_impulse_applied = false

func _tick(delta):
	var body = agent as CharacterBody2D
	if body == null:
		return FAILURE

	if not _impulse_applied:
		var target = blackboard.get_var(target_var, null)
		var dir = 1.0

		if target is Node2D:
			var dx = target.global_position.x - body.global_position.x
			dir = sign(dx)
			if dir == 0.0:
				dir = 1.0
		else:
			dir = 1.0

		var v = body.velocity
		v.x = dir * dash_speed
		body.velocity = v

		_impulse_applied = true

	if elapsed_time >= duration:
		return SUCCESS

	return RUNNING

func _exit() -> void:
	_impulse_applied = false
