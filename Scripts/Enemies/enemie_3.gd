extends CharacterBody2D

signal damage(value: float)
signal died

var speed := 150.0
var player: CharacterBody2D = null
var dead := false
var reported_dead := false
var target_in_range: CharacterBody2D = null
@onready var audio_ataque: AudioStreamPlayer2D = $audio_golpe
@onready var label: Label = $Label
@onready var bar_5: ProgressBar = $ProgressBar_enemy_3
@onready var area: Area2D = $Area2D
@onready var sfx_hit: AudioStreamPlayer2D = $hit
@onready var explosion_timer: Timer = $explosion_timer
@onready var punch_timer: Timer = $Punch_timer
@onready var sprite_2d: AnimatedSprite2D = $Sprite2D

var _attack_lock := false
var _attack_anim_lock := false
var _tween: Tween
var _stack_timer: Timer
var _stack_value := 0.0
var _label_base_pos := Vector2.ZERO
var rng := RandomNumberGenerator.new()
var face_sign := 1.0

var min_range := 70.0
var max_range := 140.0
var attack_range := 200.0
var punch_damage := 10.0
var punch_cooldown := 0.6
var lunge_dist := 38.0
var lunge_time := 0.12

var accel := 1600.0
var side_amp := 20.0
var up_amp := 10.0
var walk_freq := 1.4
var up_freq := 1.8
var walk_phase := 0.0
var walk_seed := 0.0

var pitch_variations := [0.9, 1.1, 1.3]
var pitch_variations_gun = [0.8, 1.5, 2.5]

@export var shock_duration: float = 1.5
@export var shock_factor: float = 0.35
var _shock_timer: Timer
var _base_speed: float
var _is_shocked := false

# === SISTEMA DE HITSTUN ===
@export var hitstun_duration: float = 0.8
@export var hitstun_threshold: float = 15.0
@export var combo_window: float = 1.2
@export var hitstun_color: Color = Color(1.0, 0.3, 0.3, 1.0)

var _in_hitstun := false
var _hitstun_timer: Timer
var _combo_timer: Timer
var _combo_count := 0
var _original_color: Color
var _hitstun_tween: Tween

const MONEDA = preload("res://Scenes/moneda.tscn")

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	add_to_group("enemy_3")
	
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
	
	# Electroshock
	_base_speed = speed
	_shock_timer = Timer.new()
	_shock_timer.one_shot = true
	add_child(_shock_timer)
	if not _shock_timer.is_connected("timeout", Callable(self, "_end_electroshock")):
		_shock_timer.connect("timeout", Callable(self, "_end_electroshock"))

	# Sistema de hitstun
	_ready_hitstun_system()

func _ready_hitstun_system() -> void:
	# Timer para duración del hitstun
	_hitstun_timer = Timer.new()
	_hitstun_timer.one_shot = true
	add_child(_hitstun_timer)
	_hitstun_timer.connect("timeout", Callable(self, "_end_hitstun"))
	
	# Timer para ventana de combo
	_combo_timer = Timer.new()
	_combo_timer.one_shot = true
	add_child(_combo_timer)
	_combo_timer.connect("timeout", Callable(self, "_reset_combo"))
	
	# Guardar color original del sprite
	if sprite_2d:
		_original_color = sprite_2d.modulate

func _physics_process(delta: float) -> void:
	_update_target()
	if dead or player == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_player := player.global_position - global_position
	var dist := to_player.length()
	var dir := to_player.normalized()
	var target_vel := Vector2.ZERO
	walk_phase += delta
	var offset := Vector2.ZERO

	if dist > max_range * 0.9:
		var phase := walk_phase * TAU
		offset = Vector2(sin(phase * walk_freq + walk_seed) * side_amp, sin(phase * up_freq + walk_seed * 0.73) * up_amp)

	# === MODIFICACIÓN: Movimiento reducido durante hitstun ===
	var movement_multiplier = 1.0
	if _in_hitstun:
		movement_multiplier = 0.15  # 15% velocidad durante hitstun (muy lento para melee)
		offset *= 0.2  # Reducir oscilaciones también

	if _attack_lock and not _in_hitstun:  # Solo bloquear si NO está en hitstun
		if dist > attack_range or target_in_range == null:
			target_vel = Vector2.ZERO
	else:
		if dist > max_range:
			target_vel = (dir * speed + offset) * movement_multiplier
		elif dist < min_range:
			target_vel = (-dir * (speed * 0.8)) * movement_multiplier
		else:
			target_vel = (dir * (speed * 0.55) + offset * 0.4) * movement_multiplier

	if target_vel.length() > speed * movement_multiplier:
		target_vel = target_vel.normalized() * speed * movement_multiplier

	velocity = velocity.move_toward(target_vel, accel * delta)
	rotation = 0.0

	# Flip invertido (enemigo mira al lado contrario del jugador)
	if abs(dir.x) > 0.1:
		face_sign = sign(dir.x)
		sprite_2d.flip_h = face_sign > 0.0

	move_and_slide()

	# === MODIFICACIÓN: No atacar durante hitstun ===
	if (dist <= attack_range and target_in_range and punch_timer.time_left <= 0.0 
		and not dead and not _attack_lock and not _attack_anim_lock and not _in_hitstun):
		_do_punch(dir)

func _do_punch(dir: Vector2) -> void:
	# No atacar si está en hitstun
	if _in_hitstun:
		return
		
	if target_in_range:
		var direction_to_player = (target_in_range.global_position - global_position).normalized()
		if direction_to_player.x != 0:
			face_sign = sign(direction_to_player.x)
			sprite_2d.flip_h = face_sign > 0.0
		
		if target_in_range.has_method("emit_signal"):
			target_in_range.emit_signal("damage", punch_damage)
	
	# Reproducir sonido de golpe
	if audio_ataque:
		audio_ataque.stop()
		audio_ataque.play()
	
	if sprite_2d:
		sprite_2d.play("ataque")
		_attack_anim_lock = true

	_attack_lock = true
	if _tween and _tween.is_running():
		_tween.kill()
	
	# Movimiento de embestida (solo si no está en hitstun)
	if not _in_hitstun:
		var start := global_position
		var end := start + dir * lunge_dist
		_tween = create_tween()
		_tween.tween_property(self, "global_position", end, lunge_time)
		_tween.tween_property(self, "global_position", start, lunge_time)
	
	punch_timer.start(punch_cooldown)

func _on_punch_timer_timeout() -> void:
	_attack_lock = false

func _on_sprite_2d_animation_finished() -> void:
	if sprite_2d.animation == "ataque":
		_attack_anim_lock = false
		sprite_2d.play("idle")
	elif sprite_2d.animation == "explosion":
		if explosion_timer and explosion_timer.time_left > 0.0:
			explosion_timer.stop()
		if _is_shocked:
			_end_electroshock()
		if not reported_dead:
			# Registrar eliminación
			var killer_id = _determine_killer()
			if killer_id != "":
				# KillTracker.register_kill(killer_id, "enemy_3")  # Descomentar si tienes KillTracker
				pass
			reported_dead = true
			_drop_coin()
			emit_signal("died")
		queue_free()

func _determine_killer() -> String:
	"""Determina qué jugador mató a este enemigo basado en proximidad"""
	var players = []
	players += get_tree().get_nodes_in_group("player")
	players += get_tree().get_nodes_in_group("player_2")
	
	var closest_player = null
	var closest_dist = INF
	
	for p in players:
		if p and p is Node2D:
			var dist = global_position.distance_to(p.global_position)
			if dist < closest_dist and dist < 200.0:
				closest_dist = dist
				closest_player = p
	
	if closest_player:
		if closest_player.is_in_group("player"):
			return "player1"
		elif closest_player.is_in_group("player_2"):
			return "player2"
	
	return ""

# === COLISIONES ===
func _on_area_2d_body_entered(body: Node2D) -> void:
	if dead:
		return
	if body.is_in_group("player") or body.is_in_group("player_2"):
		target_in_range = body as CharacterBody2D
		if body.has_method("emit_signal"):
			body.emit_signal("damage", punch_damage)
	if body.is_in_group("player_1_bullet"):
		emit_signal("damage", 30.0)
		if body.has_method("queue_free"):
			body.queue_free()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == target_in_range:
		target_in_range = null

func _on_area_2d_area_entered(a: Area2D) -> void:
	if a.is_in_group("player_1_bullet"):
		emit_signal("damage", 20.0)
		if a.has_method("queue_free"):
			a.queue_free()
	elif a.is_in_group("puño_player_2"):
		emit_signal("damage", 20.0)
		if a.has_method("queue_free"):
			a.queue_free()

# === SISTEMA DE DAÑO CON HITSTUN ===
func _on_damage(amount: float) -> void:
	if bar_5:
		bar_5.value = clamp(bar_5.value - amount, bar_5.min_value, bar_5.max_value)
	
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

	if _tween and _tween.is_running() and not _attack_lock:
		_tween.kill()
		
	var t := create_tween()
	t.tween_property(label, "position:y", _label_base_pos.y - 16.0, 0.22)
	t.parallel().tween_property(label, "scale", Vector2(1.2, 1.2), 0.16)
	t.parallel().tween_property(label, "modulate:a", 0.0, 0.32).set_delay(0.04)
	_stack_timer.start(0.4)
	random_pitch_variations_gun()

	# === NUEVO: SISTEMA DE HITSTUN ===
	_process_hitstun(amount)

	if not dead and bar_5 and bar_5.value <= bar_5.min_value:
		_die()

func _process_hitstun(damage_amount: float) -> void:
	# Solo activa hitstun si el daño es suficiente
	if damage_amount < hitstun_threshold:
		return
	
	# Incrementa combo si estamos en ventana de combo
	if _combo_timer.time_left > 0.0:
		_combo_count += 1
	else:
		_combo_count = 1
	
	# Reinicia timer de combo
	_combo_timer.start(combo_window)
	
	# Activa/extiende hitstun
	_enter_hitstun()
	
	# Duración del hitstun se extiende con combos
	var extended_duration = hitstun_duration + (_combo_count * 0.15)
	_hitstun_timer.start(extended_duration)
	
	print("Combo Melee x", _combo_count, " - Hitstun: ", extended_duration, "s")

func _enter_hitstun() -> void:
	if dead:
		return
		
	_in_hitstun = true
	
	# Para el timer de ataque melee
	if punch_timer:
		punch_timer.paused = true
	
	# Si estaba atacando, cancelar el ataque
	if _attack_lock:
		_cancel_current_attack()
	
	# Cambia color a rojo con animación suave
	if _hitstun_tween:
		_hitstun_tween.kill()
	
	_hitstun_tween = create_tween()
	_hitstun_tween.tween_property(sprite_2d, "modulate", hitstun_color, 0.08)
	
	# Reducir velocidad durante hitstun
	speed *= 0.25  # 25% de velocidad
	
	# Efecto de sacudida
	_screen_shake_effect_melee()
	
	# Reproducir animación de hitstun si existe
	if sprite_2d and sprite_2d.sprite_frames.has_animation("hitstun"):
		sprite_2d.play("hitstun")

func _end_hitstun() -> void:
	if not _in_hitstun:
		return
		
	_in_hitstun = false
	
	# Reactiva ataque
	if punch_timer and not dead:
		punch_timer.paused = false
	
	# Restaura color original
	if _hitstun_tween:
		_hitstun_tween.kill()
	
	_hitstun_tween = create_tween()
	_hitstun_tween.tween_property(sprite_2d, "modulate", _original_color, 0.15)
	
	# Restaura velocidad (si no está en electroshock)
	if not _is_shocked:
		speed = _base_speed
	
	# Volver a animación idle
	if not dead and sprite_2d and sprite_2d.sprite_frames.has_animation("idle"):
		sprite_2d.play("idle")
	
	print("Hitstun Melee terminado")

func _cancel_current_attack() -> void:
	# Cancela ataque en progreso
	_attack_lock = false
	_attack_anim_lock = false
	
	# Para cualquier tween de movimiento de ataque
	if _tween and _tween.is_running():
		_tween.kill()
	
	# Para timer de ataque
	if punch_timer:
		punch_timer.stop()

func _reset_combo() -> void:
	if _combo_count > 1:
		print("Combo Melee terminado: ", _combo_count, " golpes!")
	_combo_count = 0

func _screen_shake_effect_melee() -> void:
	# Efecto de sacudida del sprite
	var shake_tween = create_tween()
	var original_pos = sprite_2d.position
	
	# Sacudida intensa
	for i in range(5):
		var offset = Vector2(randf_range(-6, 6), randf_range(-6, 6))
		shake_tween.tween_property(sprite_2d, "position", original_pos + offset, 0.03)
		shake_tween.tween_property(sprite_2d, "position", original_pos, 0.03)

func _on_stack_timeout() -> void:
	_stack_value = 0.0
	label.visible = false

func _die() -> void:
	dead = true
	
	# Limpia hitstun antes de morir
	if _hitstun_timer:
		_hitstun_timer.stop()
	if _combo_timer:
		_combo_timer.stop()
	_end_hitstun()
	
	if _is_shocked:
		_end_electroshock()
	
	label.visible = false
	velocity = Vector2.ZERO
	area.set_deferred("monitoring", false)
	punch_timer.stop()
	
	var col := get_node_or_null("CollisionShape2D")
	if col:
		col.set_deferred("disabled", true)
		
	if sprite_2d and sprite_2d.sprite_frames and sprite_2d.sprite_frames.has_animation("explosion"):
		sprite_2d.sprite_frames.set_animation_loop("explosion", false)
		sprite_2d.frame = 0
		sprite_2d.play("explosion")
		if explosion_timer.time_left > 0.0:
			explosion_timer.stop()
	else:
		explosion_timer.start(0.3)

func _update_target() -> void:
	var players := []
	players += get_tree().get_nodes_in_group("player")
	players += get_tree().get_nodes_in_group("player_2")
	var nearest: Node2D = null
	var nearest_dist := INF
	for p in players:
		if p and p is Node2D:
			var dist = global_position.distance_to(p.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = p
	player = nearest

func _drop_coin() -> void:
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
	if not _is_shocked:
		_base_speed = speed
		_is_shocked = true
		speed = min(speed, _base_speed * factor)
		_shock_timer.start(duration)

func _end_electroshock() -> void:
	_is_shocked = false
	speed = _base_speed

func random_pitch_variations_gun() -> void:
	var random_pitch = pitch_variations_gun[randi() % pitch_variations_gun.size()]
	if sfx_hit:
		sfx_hit.pitch_scale = random_pitch
		sfx_hit.play()
