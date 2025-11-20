@tool
extends BTAction

@export var dash_speed: float = 800.0              # fuerza horizontal del impulso
@export var duration: float = 0.20                 # cuánto dura el estado de dash
@export var target_var: StringName = &"target"     # Node2D / CharacterBody2D del player

var _impulse_applied: bool = false

func _generate_name() -> String:
	return "BossDashImpulseToTarget  dash: %s  dur: %ss" % [
		dash_speed,
		duration,
	]

func _enter() -> void:
	_impulse_applied = false

func _tick(delta: float) -> Status:
	var body := agent as CharacterBody2D
	if body == null:
		return FAILURE

	# Aplicamos el impulso SOLO una vez
	if not _impulse_applied:
		var target = blackboard.get_var(target_var, null)
		var dir: float = 1.0

		if target is Node2D:
			var dx = target.global_position.x - body.global_position.x
			dir = sign(dx)
			if dir == 0.0:
				dir = 1.0
		else:
			# si no hay target en el BB, por defecto a la derecha
			dir = 1.0

		var v := body.velocity
		v.x = dir * dash_speed   # SOLO X, sin jump
		body.velocity = v

		_impulse_applied = true

	# NO hacemos move_and_slide aquí, lo hace tu final_boss.gd

	if elapsed_time >= duration:
		return SUCCESS

	return RUNNING

func _exit() -> void:
	_impulse_applied = false
