extends CharacterBody2D
signal damage(value: float)
signal died
var speed := 150.0
var player: CharacterBody2D = null
@onready var label: Label = $Label
@onready var bar_4: ProgressBar = $ProgressBar_enemy_2
@onready var area: Area2D = $Area2D
@onready var sfx_hit: AudioStreamPlayer2D = $hit
@onready var explosion_timer: Timer = $explosion_timer
@onready var punch_timer: Timer = $Punch_timer
@onready var sprite_2d: AnimatedSprite2D = $AnimatedSprite2D  # AnimatedSprite2D

var min_range := 70.0
var max_range := 140.0
var attack_range := 160.0
var punch_damage := 10.0
var punch_cooldown := 0.6
var lunge_dist := 38.0
var lunge_time := 0.12

var accel := 1200.0
var side_amp := 90.0
var up_amp := 60.0
var walk_freq := 1.6
var up_freq := 2.1
var walk_phase := 0.0
var walk_seed := 0.0
var calm_start := 120.0
var calm_end := 80.0
const MONEDA = preload("res://Scenes/moneda.tscn")
var _stack_value := 0.0
var _label_base_pos := Vector2.ZERO
var _tween: Tween
var _stack_timer: Timer
var dead := false
var reported_dead := false
var target_in_range: CharacterBody2D = null
var rng := RandomNumberGenerator.new()
var pitch_variations := [0.9, 1.1, 1.3]
var _attack_lock := false
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
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	add_to_group("enemy_2")
	_label_base_pos = label.position
	label.visible = false
	rng.randomize()
	walk_seed = rng.randf() * TAU
	area.monitoring = true
	if not area.is_connected("body_entered", Callable(self, "_on_area_2d_body_entered")):
		area.connect("body_entered", Callable(self, "_on_area_2d_body_entered"))
	if not area.is_connected("body_exited", Callable(self, "_on_area_2d_body_exited")):
		area.connect("body_exited", Callable(self, "_on_area_2d_body_exited"))
	if not area.is_connected("area_entered", Callable(self, "_on_area_2d_area_entered")):
		area.connect("area_entered", Callable(self, "_on_area_2d_area_entered"))
	punch_timer.one_shot = true
	if not punch_timer.is_connected("timeout", Callable(self, "_on_punch_timer_timeout")):
		punch_timer.connect("timeout", Callable(self, "_on_punch_timer_timeout"))
	_stack_timer = Timer.new()
	_stack_timer.one_shot = true
	add_child(_stack_timer)
	_stack_timer.connect("timeout", Callable(self, "_on_stack_timeout"))
	if sprite_2d and not sprite_2d.is_connected("animation_finished", Callable(self, "_on_sprite_2d_animation_finished")):
		sprite_2d.connect("animation_finished", Callable(self, "_on_sprite_2d_animation_finished"))

	if not is_connected("damage", Callable(self, "_on_damage")):
		connect("damage", Callable(self, "_on_damage"))
		
	#---ELECTROSHOCK
	_base_speed = speed

	_shock_timer = Timer.new()
	_shock_timer.one_shot = true
	add_child(_shock_timer)
	if not _shock_timer.is_connected("timeout", Callable(self, "_end_electroshock")):
		_shock_timer.connect("timeout", Callable(self, "_end_electroshock"))

	# Iniciar con Idle
	if sprite_2d and sprite_2d.sprite_frames.has_animation("Idle"):
		sprite_2d.play("Idle")

func _physics_process(delta: float) -> void:
	_update_target()
	if dead or player == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_player := player.global_position - global_position
	var dist := to_player.length()
	var dir := to_player.normalized()
	var tangent := Vector2(-dir.y, dir.x)

	walk_phase += delta
	var calm = clamp((dist - calm_end) / max(1.0, calm_start - calm_end), 0.12, 1.0)

	var offset = tangent * (sin(walk_phase * TAU * walk_freq + walk_seed) * side_amp * calm)
	offset += Vector2(0, 1) * (sin(walk_phase * TAU * up_freq + walk_seed * 0.73) * up_amp * calm)

	var target_vel := Vector2.ZERO
	if _attack_lock:
		target_vel = Vector2.ZERO
	else:
		if dist > max_range:
			target_vel = dir * speed + offset
		elif dist < min_range:
			target_vel = dir * (speed * 0.15) + offset * 0.25
		else:
			target_vel = dir * (speed * 0.35) + offset * 0.6
		if target_vel.length() > speed:
			target_vel = target_vel.normalized() * speed

	velocity = velocity.move_toward(target_vel, accel * delta)
	rotation = 0.0
	
	# 👀 Corrección aquí:
	sprite_2d.flip_h = dir.x > 0.0

	move_and_slide()

	if dist <= attack_range and target_in_range and punch_timer.time_left <= 0.0 and not dead:
		_do_punch(dir)


func _drop_coin():
	var coin_instance = MONEDA.instantiate()
	get_parent().add_child(coin_instance)
	coin_instance.global_position = global_position
	var sprite = coin_instance.get_node("AnimatedSprite2D")
	if sprite:
		sprite.play("idle")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("player_2"):
		target_in_range = body as CharacterBody2D
	if body.is_in_group("player_1_bullet"):
		emit_signal("damage", 10.0,"golpe")
		if body.has_method("queue_free"):
			body.queue_free()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == target_in_range:
		target_in_range = null

func _on_area_2d_area_entered(a: Area2D) -> void:
	if a.is_in_group("player_1_bullet"):
		emit_signal("damage", 10.0)
		if a.has_method("queue_free"):
			a.queue_free()
	elif a.is_in_group("puño_player_2"):
		emit_signal("damage", 20.0)
		if a.has_method("queue_free"):
			a.queue_free()
			
func _do_punch(dir: Vector2) -> void:
	if target_in_range:
		print("💥 Enemigo golpea al jugador con daño:", punch_damage)
		target_in_range.emit_signal("damage", punch_damage)
		if sfx_hit:
			sfx_hit.pitch_scale = pitch_variations[rng.randi_range(0, pitch_variations.size() - 1)]
			sfx_hit.play()
			
	_attack_lock = true
	if _tween and _tween.is_running():
		_tween.kill()
		
	# Animación de golpe
	if sprite_2d and sprite_2d.sprite_frames.has_animation("golpe"):
		sprite_2d.play("golpe")
		
	# Movimiento de embestida
	var start := global_position
	var end := start + dir * lunge_dist
	_tween = create_tween()
	_tween.tween_property(self, "global_position", end, lunge_time)
	_tween.tween_property(self, "global_position", start, lunge_time)

	# Cooldown del ataque
	punch_timer.start(punch_cooldown)

func _on_punch_timer_timeout() -> void:
	_attack_lock = false
	# volver a Idle si no está muerto
	if not dead and sprite_2d and sprite_2d.sprite_frames.has_animation("Idle"):
		sprite_2d.play("Idle")

func _on_damage(amount: float) -> void:
	if bar_4:
		bar_4.value = clamp(bar_4.value - amount, bar_4.min_value, bar_4.max_value)
	_stack_value += amount
	label.text = str(int(_stack_value))
	label.visible = true
	label.position = _label_base_pos
	label.scale = Vector2.ONE
	var sum := int(_stack_value)
	var col := Color(1, 1, 1, 1)
	if sum <= 20:
		col = Color(1, 1, 1, 1)
	elif sum <= 40:
		col = Color(1, 1, 0, 1)
	else:
		col = Color(1, 0, 0, 1)
	label.modulate = col
	if _tween and _tween.is_running() and _attack_lock == false:
		_tween.kill()
	var t := create_tween()
	t.tween_property(label, "position:y", _label_base_pos.y - 16.0, 0.22)
	t.parallel().tween_property(label, "scale", Vector2(1.2, 1.2), 0.16)
	t.parallel().tween_property(label, "modulate:a", 0.0, 0.32).set_delay(0.04)
	_stack_timer.start(0.4)
	random_pitch_variations_gun()
	if not dead and bar_4 and bar_4.value <= bar_4.min_value:
		_die()

func _on_stack_timeout() -> void:
	_stack_value = 0.0
	label.visible = false

func _die() -> void:
	dead = true
	if _is_shocked:
		_end_electroshock()
	label.visible = false
	velocity = Vector2.ZERO
	area.monitoring = false
	punch_timer.stop()
	var col := get_node_or_null("CollisionShape2D")
	if col:
		col.disabled = true
	if sprite_2d and sprite_2d.sprite_frames and sprite_2d.sprite_frames.has_animation("explosion"):
		sprite_2d.sprite_frames.set_animation_loop("explosion", false)
		sprite_2d.frame = 0
		sprite_2d.play("explosion")
		if explosion_timer.time_left > 0.0:
			explosion_timer.stop()
	else:
		explosion_timer.start(0.3)

func _on_sprite_2d_animation_finished() -> void:
	if sprite_2d.animation == "golpe":
		_attack_lock = false
		# regresar a Idle
		if not dead and sprite_2d.sprite_frames.has_animation("Idle"):
			sprite_2d.play("Idle")
		return
		
	if sprite_2d.animation == "explosion":
		if explosion_timer and explosion_timer.time_left > 0.0:
			explosion_timer.stop()
		if _is_shocked:
			_end_electroshock() 
		if not reported_dead:
			reported_dead = true
			_drop_coin()
			emit_signal("died")
		queue_free()

func _on_explosion_timer_timeout() -> void:
	if not reported_dead:
		reported_dead = true
		emit_signal("died")
	queue_free()

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
	
func electroshock(duration: float = -1.0, factor: float = -1.0) -> void:
	if dead:
		return
	if duration <= 0.0:
		duration = shock_duration
	if factor <= 0.0:
		factor = shock_factor
	if not _is_shocked:
		_base_speed = speed
		_is_shocked = true
	speed = min(speed, _base_speed * factor)
	_shock_timer.start(duration)
	
func _end_electroshock() -> void:
	_is_shocked = false
	speed = _base_speed
