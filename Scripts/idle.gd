extends State
class_name Idle

@export var wait_time_min := 0.25
@export var wait_time_max := 0.6
@export var wake_distance := 99999.0

var _t := 0.0
var _wait := 0.5
var _anim: AnimatedSprite2D

func enter() -> void:
	super.enter()
	_t = 0.0
	_wait = randf_range(wait_time_min, wait_time_max)
	if _anim == null:
		_anim = actor.get_node_or_null("AnimatedSprite2D")
	if _anim:
		_anim.play("idle")

	var body := actor as CharacterBody2D
	if body:
		body.velocity = Vector2.ZERO

func physics_update(delta: float) -> void:
	_t += delta
	var p := _get_player()
	if p == null: return
	if _t >= _wait:
		var dist := actor.global_position.distance_to(p.global_position)
		if dist <= wake_distance:
			fsm.transition_to("Follow")
