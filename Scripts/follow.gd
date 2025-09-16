extends State
class_name Follow

@export var speed := 150.0
@export var accel := 1400.0
@export var desired_dist := 260.0
@export var deadzone := 18.0

@export var dash_min_range := 120.0
@export var dash_max_range := 520.0
@export var dash_cooldown := 2.0

var _cd: Timer
var _anim: AnimatedSprite2D

func _ready() -> void:
	_cd = Timer.new()
	_cd.one_shot = true
	add_child(_cd)

func enter(msg := {}) -> void:
	super.enter(msg)
	if _anim == null:
		_anim = actor.get_node_or_null("AnimatedSprite2D")
	if _anim:
		_anim.play("walk")

func physics_update(delta: float) -> void:
	var p := _get_player()
	if p == null:
		fsm.transition_to("Idle")
		return

	var to := p.global_position - actor.global_position
	var dist := to.length()
	var dir
	if dist > 0.0:
		dir = to / dist
	else:
		dir = Vector2.ZERO
	# Control proporcional para mantener una distancia
	var err := dist - desired_dist
	var target_vel := Vector2.ZERO
	if abs(err) > deadzone:
		var kp := 4.0
		var radial_speed = clamp(err * kp, -speed, speed)
		target_vel = dir * radial_speed

	# **Mover al boss** (CharacterBody2D)
	var body := actor as CharacterBody2D
	if body:
		body.velocity = body.velocity.move_toward(target_vel, accel * delta)
		body.move_and_slide()

	# Voltear sprite
	if _anim:
		_anim.flip_h = dir.x < 0.0
		_anim.flip_v = false

	# ¿Dash?
	if (_cd.time_left <= 0.0) and (dist >= dash_min_range) and (dist <= dash_max_range):
		fsm.transition_to("Dash", {"dir": dir})
		_cd.start(dash_cooldown)
