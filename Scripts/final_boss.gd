extends CharacterBody2D

@export var dead: bool = false
@export var dash_speed: float = 1200.0
@export var dash_duration: float = 0.35

@export var dash_damage: float = 30.0
@export var attack_damage: float = 25.0
@export var shout_damage: float = 15.0
@export var poison_damage: float = 10.0

@export var contact_damage: float = 20.0

var main_sm: LimboHSM
var using_ability: bool = false
var is_dashing: bool = false
var dash_dir: float = 10.0
var dash_time_left: float = 0.0

var _current_damage: float = 0.0
var _current_source: String = "golpe"

@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	if attack_damage <= 0.0:
		attack_damage = 25.0
	if dash_damage <= 0.0:
		dash_damage = 30.0
	if shout_damage <= 0.0:
		shout_damage = 15.0
	if poison_damage <= 0.0:
		poison_damage = 10.0
	if contact_damage <= 0.0:
		contact_damage = 20.0

	_current_damage = contact_damage
	_current_source = "contact"

	_initate_state_machine()

	if hitbox and not hitbox.body_entered.is_connected(Callable(self, "_on_hitbox_body_entered")):
		hitbox.body_entered.connect(Callable(self, "_on_hitbox_body_entered"))
	if hitbox:
		hitbox.monitoring = true


func _initate_state_machine() -> void:
	main_sm = LimboHSM.new()
	add_child(main_sm)
	
	var idle_state = LimboState.new().named("idle").call_on_enter(_idle_start).call_on_update(_idle_update)
	var walk_state = LimboState.new().named("walk").call_on_enter(_walk_start).call_on_update(_walk_update)
	var attack_state = LimboState.new().named("attack").call_on_enter(_attack_start).call_on_update(_attack_update)
	var dash_state = LimboState.new().named("dash").call_on_enter(_dash_start).call_on_update(_dash_update)
	var shout_state = LimboState.new().named("shout").call_on_enter(_shout_start).call_on_update(_shout_update)
	var poison_state = LimboState.new().named("posion").call_on_enter(_poison_start).call_on_update(_poison_update)
	var death_state = LimboState.new().named("death").call_on_enter(_death_start).call_on_update(_death_update)
	
	main_sm.add_child(idle_state)
	main_sm.add_child(walk_state)
	main_sm.add_child(attack_state)
	main_sm.add_child(dash_state)
	main_sm.add_child(shout_state)
	main_sm.add_child(poison_state)
	main_sm.add_child(death_state)
	
	main_sm.initial_state = idle_state
	main_sm.add_transition(idle_state, walk_state, &"to_walk")
	main_sm.add_transition(main_sm.ANYSTATE, idle_state, &"state_ended")
	main_sm.add_transition(main_sm.ANYSTATE, attack_state, &"to_attack")
	main_sm.add_transition(main_sm.ANYSTATE, dash_state, &"to_dash")
	main_sm.add_transition(main_sm.ANYSTATE, shout_state, &"to_shout")
	main_sm.add_transition(main_sm.ANYSTATE, poison_state, &"to_poison")
	main_sm.add_transition(main_sm.ANYSTATE, death_state, &"to_death")
	
	main_sm.initialize(self)
	main_sm.set_active(true)


func _idle_start() -> void:
	$Sprite2D.play("idle")


func _idle_update(_delta: float) -> void:
	if using_ability or is_dashing:
		return
	if velocity.x != 0.0:
		main_sm.dispatch(&"to_walk")


func _walk_start() -> void:
	$Sprite2D.play("walk")


func _walk_update(_delta: float) -> void:
	if using_ability or is_dashing:
		return
	if velocity.x == 0.0:
		main_sm.dispatch(&"state_ended")


func _attack_start() -> void:
	using_ability = true
	$Attack_timer.start()
	velocity.x = 0.0
	$Sprite2D.play("attack")
	_current_damage = attack_damage
	_current_source = "golpe"


func _attack_update(_delta: float) -> void:
	if $Attack_timer.is_stopped():
		using_ability = false
		_current_damage = contact_damage
		_current_source = "contact"
		main_sm.dispatch(&"state_ended")


func _dash_start() -> void:
	using_ability = true
	is_dashing = true
	dash_time_left = dash_duration
	$Sprite2D.play("dash")
	_current_damage = dash_damage
	_current_source = "golpe"


func _dash_update(delta: float) -> void:
	if not is_dashing:
		return
	dash_time_left -= delta
	velocity.x = dash_dir * dash_speed
	if dash_time_left <= 0.0:
		velocity.x = 0.0
		is_dashing = false
		using_ability = false
		_current_damage = contact_damage
		_current_source = "contact"
		main_sm.dispatch(&"state_ended")


func _shout_start() -> void:
	using_ability = true
	$Shout_timer.start()
	velocity.x = 0.0
	$Sprite2D.play("shout")
	_current_damage = shout_damage
	_current_source = "grito"


func _shout_update(_delta: float) -> void:
	if $Shout_timer.is_stopped():
		using_ability = false
		_current_damage = contact_damage
		_current_source = "contact"
		main_sm.dispatch(&"state_ended")


func _poison_start() -> void:
	using_ability = true
	$Poison_timer.start()
	velocity.x = 0.0
	$Sprite2D.play("poison")
	_current_damage = poison_damage
	_current_source = "veneno"


func _poison_update(_delta: float) -> void:
	if $Poison_timer.is_stopped():
		using_ability = false
		_current_damage = contact_damage
		_current_source = "contact"
		main_sm.dispatch(&"state_ended")


func _death_start() -> void:
	dead = true
	velocity = Vector2.ZERO
	$Sprite2D.play("death")


func _death_update(_delta: float) -> void:
	pass


func flip_sprite(dir: float) -> void:
	if dir > 0.0:
		$Sprite2D.flip_h = true
	elif dir < 0.0:
		$Sprite2D.flip_h = false


func move(dir, speed):
	if dead:
		return
	if using_ability or is_dashing:
		return
	velocity.x = dir * speed
	flip_sprite(dir)


func start_attack() -> void:
	if dead:
		return
	if using_ability or is_dashing:
		return
	velocity.x = 0.0
	main_sm.dispatch(&"to_attack")


func start_dash_towards(target: Node2D) -> void:
	if dead:
		return
	if using_ability or is_dashing:
		return
	var dir = sign(target.global_position.x - global_position.x)
	if dir == 0.0:
		dir = 1.0
	dash_dir = dir
	flip_sprite(dir)
	main_sm.dispatch(&"to_dash")


func start_shout() -> void:
	if dead:
		return
	if using_ability or is_dashing:
		return
	main_sm.dispatch(&"to_shout")


func start_poison() -> void:
	if dead:
		return
	if using_ability or is_dashing:
		return
	main_sm.dispatch(&"to_poison")


func die() -> void:
	if dead:
		return
	main_sm.dispatch(&"to_death")


func is_using_ability() -> bool:
	return using_ability or is_dashing


func check_for_self(node) -> bool:
	return node == self


func _physics_process(delta: float) -> void:
	if dead:
		velocity = Vector2.ZERO
	move_and_slide()


func _on_hitbox_body_entered(body: Node2D) -> void:
	if dead:
		return
	if not body.is_in_group("players"):
		return

	var dmg = _current_damage
	if dmg <= 0.0:
		dmg = contact_damage

	print("Boss hitbox → colisión con: ", body.name, " daño: ", dmg, " fuente: ", _current_source)

	if body.has_method("apply_damage"):
		body.call("apply_damage", dmg, _current_source)
	elif body.has_signal("damage"):
		body.emit_signal("damage", dmg, _current_source)
