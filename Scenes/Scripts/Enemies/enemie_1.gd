extends CharacterBody2D

signal damage(value: float)
signal died

var speed := 300
var player: CharacterBody2D = null
const BULLET_ENEMY_1 = preload("res://Scenes/gun_enemy_1.tscn")
@onready var label: Label = $Label
@onready var bar_3: ProgressBar = $ProgressBar_enemy
@onready var anim: AnimatedSprite2D = $Sprite2D
const MONEDA = preload("res://Scenes/moneda.tscn")
var min_range := 250.0
var max_range := 280.0
var attack_range := 400.0
var bullet_speed := 700.0

var _stack_value := 0.0
var _stack_timer: Timer
var _label_base_pos := Vector2.ZERO
var _tween: Tween
var dead := false
var reported_dead := false

var strafe_speed := 220.0
var accel := 1200.0
var desired_dist := 300.0
var orbit_dir := 1.0
var swap_interval := 1.6
var strafe_timer: Timer
var rng := RandomNumberGenerator.new()
var wiggle_t := 0.0
var wiggle_amp := 40.0
var wiggle_freq := 1.6
var pitch_variations_gun = [0.8, 1.5, 2.5]

@export var shock_duration: float = 1.5   # segundos de lentitud
@export var shock_factor: float   = 0.35  # 35% de la velocidad original

var _shock_timer: Timer
var _base_speed: float
var _is_shocked := false

func random_pitch_variations_gun():
	var random_pitch = pitch_variations_gun[randi()%pitch_variations_gun.size()]
	$hit.pitch_scale = random_pitch
	$hit.play()

func _ready() -> void:
	for m in get_tree().get_nodes_in_group("table"):
		if m is StaticBody2D:
			add_collision_exception_with(m)
			m.add_collision_exception_with(self)
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	$gun_timer.start()
	add_to_group("enemy_1")
	if not is_connected("damage", Callable(self, "_on_damage")):
		connect("damage", Callable(self, "_on_damage"))
	_stack_timer = Timer.new()
	_stack_timer.one_shot = true
	add_child(_stack_timer)
	_stack_timer.connect("timeout", Callable(self, "_on_stack_timeout"))
	_label_base_pos = label.position
	label.visible = false
	if anim and not anim.is_connected("animation_finished", Callable(self, "_on_AnimatedSprite2D_animation_finished")):
		anim.connect("animation_finished", Callable(self, "_on_AnimatedSprite2D_animation_finished"))
	rng.randomize()
	if rng.randf() < 0.5: 
		orbit_dir = -1.0 
	else: 
		orbit_dir = 1.0
	strafe_timer = Timer.new()
	strafe_timer.wait_time = swap_interval
	add_child(strafe_timer)
	strafe_timer.connect("timeout", Callable(self, "_on_strafe_swap"))
	strafe_timer.start()
	
	#---ELECTROSHOCK
	_base_speed = speed

	_shock_timer = Timer.new()
	_shock_timer.one_shot = true
	add_child(_shock_timer)
	if not _shock_timer.is_connected("timeout", Callable(self, "_end_electroshock")):
		_shock_timer.connect("timeout", Callable(self, "_end_electroshock"))

func _physics_process(delta: float) -> void:
	_update_target()
	if dead or player == null:
		if dead:
			velocity = Vector2.ZERO
			move_and_slide()
		return
	var to_player: Vector2 = player.global_position - global_position
	var dist := to_player.length()
	var dir := to_player.normalized()

	var desired : = desired_dist
	var deadzone := 18.0
	var err := dist - desired
	var target_vel := Vector2.ZERO
	
	if abs(err) > deadzone:
		var kp := 4.0
		var radial_speed = clamp(err*kp, -speed, speed)
		target_vel = dir * radial_speed
	else:		
		var tangent := Vector2(-to_player.y, to_player.x).normalized()
		wiggle_t += delta
		var osc := sin(wiggle_t * TAU * wiggle_freq) * wiggle_amp
		var radial := to_player.normalized() * ((desired_dist - dist) * 4.0)
		target_vel = tangent * (strafe_speed * orbit_dir + osc) + radial
	if target_vel.length() > speed:
		target_vel = target_vel.normalized() * speed
	velocity = velocity.move_toward(target_vel, accel * delta)
	move_and_slide()

func _on_strafe_swap() -> void:
	if rng.randf() < 0.7:
		orbit_dir *= -1.0
	swap_interval = rng.randf_range(1.2, 2.2)
	strafe_timer.wait_time = swap_interval

func _on_gun_timer_timeout() -> void:
	_update_target()
	if dead or player == null:
		return
	var to_player: Vector2 = player.global_position - global_position
	if to_player.length() > attack_range:
		return
	var bullet_instance = BULLET_ENEMY_1.instantiate()
	get_parent().add_child(bullet_instance)
	bullet_instance.global_position = global_position
	bullet_instance.rotation = to_player.angle()

func _on_damage(amount: float) -> void:
	if bar_3:
		bar_3.value = clamp(bar_3.value - amount, bar_3.min_value, bar_3.max_value)
	_stack_value += amount
	label.text = str(int(_stack_value))
	label.visible = true
	label.position = _label_base_pos
	label.scale = Vector2.ONE
	var sum := int(_stack_value)
	var col := Color(1, 1, 1, 1)
	if sum <= 20: col = Color(1, 1, 1, 1)
	elif sum <= 40: col = Color(1, 1, 0, 1)
	else: col = Color(1, 0, 0, 1)
	label.modulate = col
	if _tween and _tween.is_running(): _tween.kill()
	_tween = create_tween()
	_tween.tween_property(label, "position:y", _label_base_pos.y - 18.0, 0.25)
	_tween.parallel().tween_property(label, "scale", Vector2(1.25, 1.25), 0.18)
	_tween.parallel().tween_property(label, "modulate:a", 0.0, 0.35).set_delay(0.05)
	_stack_timer.start(0.4)
	random_pitch_variations_gun()
	if not dead and bar_3 and bar_3.value <= bar_3.min_value:
		dead = true
		label.visible = false
		if has_node("gun_timer"): $gun_timer.stop()
		velocity = Vector2.ZERO
		anim.play("explosion")
		$explosion_timer.start()

func _on_stack_timeout() -> void:
	_stack_value = 0.0
	label.visible = false

func _on_damage_enemy_body_entered(body: Node2D) -> void:
	if body.is_in_group("player_1_bullet") or body.is_in_group("puño_player2") :
		$AnimationPlayer.play("hit")
		emit_signal("damage", 10.0)

func _report_dead() -> void:
	if reported_dead:
		return
	reported_dead = true

	# --- limpiar electroshock antes de liberar ---
	if _shock_timer:
		_shock_timer.stop()
	_is_shocked = false
	speed = _base_speed
	# (opcional) revertir feedback visual:
	# if sprite_2d: sprite_2d.modulate = Color(1,1,1)

	# --- tu lógica de muerte ---
	_drop_coin()
	emit_signal("died")
	call_deferred("queue_free")

func _on_AnimatedSprite2D_animation_finished() -> void:
	
	if anim.animation == "explosion":
		
		_report_dead()

func _on_explosion_timer_timeout() -> void:
	_report_dead()

# cuando el enemigo esta cerca funcion
func _update_target() -> void:
	var players := []
	players += get_tree().get_nodes_in_group("player")
	players += get_tree().get_nodes_in_group("player_2")
	var nearest: CharacterBody2D = null
	var nearest_dist := INF

	for p in players:
		if p and p is Node2D:
			var dist = global_position.distance_to(p.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = p
	player = nearest
func _drop_coin():
	var coin_instance = MONEDA.instantiate()
	get_parent().add_child(coin_instance)
	coin_instance.global_position = global_position
	var sprite = coin_instance.get_node("AnimatedSprite2D")
	if sprite:
		sprite.play("idle")
		
func electroshock(duration: float = -1.0, factor: float = -1.0) -> void:
	if dead:
		return

	if duration <= 0.0:
		duration = shock_duration
	if factor <= 0.0:
		factor = shock_factor

	# Si no estaba en shock, guarda la base y aplica el slow.
	if not _is_shocked:
		_base_speed = speed
		_is_shocked = true
	# Si ya estaba en shock y llega otro, asegura el mínimo (no sube).
	speed = min(speed, _base_speed * factor)
	
	_shock_timer.start(duration)
	
func _end_electroshock() -> void:
	_is_shocked = false
	speed = _base_speed
