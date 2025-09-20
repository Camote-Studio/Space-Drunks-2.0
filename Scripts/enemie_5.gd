extends CharacterBody2D

signal damage(value: float, source: String)
signal died

# ===== Movimiento directo =====
var speed := 200.0
var accel := 1800.0
const MONEDA = preload("res://Scenes/moneda.tscn")

# ===== Agarre =====
enum State { CHASE, GRAB }
var state := State.CHASE
var grab_range := 100.0
var grab_duration := 3.0
var grab_dps := 8.0
var grab_tick := 0.25
var grab_cooldown := 1.2
var attach_offset := 8.0

# ===== Refs =====
var player: CharacterBody2D = null
@onready var label: Label = $Label
@onready var area: Area2D = $Area2D
@onready var sfx_hit: AudioStreamPlayer2D = $hit
@onready var explosion_timer: Timer = $explosion_timer
@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var bar_7: ProgressBar = $ProgressBar_enemy_5

# Timers
var _stack_timer: Timer
var _grab_timer: Timer
var _grab_cd_timer: Timer
var _dot_timer: Timer

# Varios
var _stack_value := 0.0
var _label_base_pos := Vector2.ZERO
var _tween: Tween
var dead := false
var reported_dead := false
var rng := RandomNumberGenerator.new()
var face_sign := 1.0

@export var shock_duration: float = 1.5
@export var shock_factor: float = 0.35

var _shock_timer: Timer
var _base_speed: float
var _is_shocked := false

# === SISTEMA DE HITSTUN ===
@export var hitstun_duration: float = 1.0        # Duración mayor para enemigo especial
@export var hitstun_threshold: float = 15.0      # Daño mínimo para activar hitstun
@export var combo_window: float = 1.4            # Ventana de combo más amplia
@export var hitstun_color: Color = Color(1.0, 0.2, 0.2, 1.0)  # Rojo más intenso

var _in_hitstun := false
var _hitstun_timer: Timer
var _combo_timer: Timer
var _combo_count := 0
var _original_color: Color
var _hitstun_tween: Tween

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	add_to_group("enemy_5")

	if bar_7:
		bar_7.value = bar_7.max_value

	_label_base_pos = label.position
	label.visible = false
	rng.randomize()

	area.monitoring = true
	if not area.is_connected("body_entered", Callable(self, "_on_area_2d_body_entered")):
		area.connect("body_entered", Callable(self, "_on_area_2d_body_entered"))
	if not area.is_connected("body_exited", Callable(self, "_on_area_2d_body_exited")):
		area.connect("body_exited", Callable(self, "_on_area_2d_body_exited"))
	if not area.is_connected("area_entered", Callable(self, "_on_area_2d_area_entered")):
		area.connect("area_entered", Callable(self, "_on_area_2d_area_entered"))

	_stack_timer = Timer.new(); _stack_timer.one_shot = true; add_child(_stack_timer)
	_stack_timer.connect("timeout", Callable(self, "_on_stack_timeout"))

	_grab_timer = Timer.new(); _grab_timer.one_shot = true; add_child(_grab_timer)
	_grab_timer.connect("timeout", Callable(self, "_on_grab_timer_timeout"))

	_grab_cd_timer = Timer.new(); _grab_cd_timer.one_shot = true; add_child(_grab_cd_timer)
	_grab_cd_timer.connect("timeout", Callable(self, "_on_grab_cd_timeout"))

	_dot_timer = Timer.new(); _dot_timer.one_shot = false; _dot_timer.wait_time = grab_tick; add_child(_dot_timer)
	_dot_timer.connect("timeout", Callable(self, "_on_dot_tick"))

	if sprite_2d and not sprite_2d.is_connected("animation_finished", Callable(self, "_on_sprite_2d_animation_finished")):
		sprite_2d.connect("animation_finished", Callable(self, "_on_sprite_2d_animation_finished"))
	if not is_connected("damage", Callable(self, "_on_damage")):
		connect("damage", Callable(self, "_on_damage"))
	
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

	# === MODIFICACIÓN: Movimiento y comportamiento durante hitstun ===
	var movement_multiplier = 1.0
	if _in_hitstun:
		movement_multiplier = 0.1  # 10% velocidad durante hitstun (muy severo para enemy_5)
		# Durante hitstun, cancelar grab si está activo
		if state == State.GRAB:
			_cancel_grab()
			
	var target_vel: Vector2 = Vector2.ZERO
	match state:
		State.CHASE:
			#var target_vel := dir * speed * movement_multiplier
			velocity = velocity.move_toward(target_vel, accel * delta)
			# No puede iniciar grab durante hitstun
			if dist <= grab_range and _grab_cd_timer.time_left <= 0.0 and not _in_hitstun:
				_start_grab()
		State.GRAB:
			if not _in_hitstun:  # Solo hacer grab si no está en hitstun
				var anchor := player.global_position - dir * attach_offset
				global_position = global_position.move_toward(anchor, accel * delta * 0.02)
			velocity = Vector2.ZERO

	if abs(dir.x) > 0.1:
		face_sign = sign(dir.x)
	sprite_2d.flip_h = face_sign < 0.0

	move_and_slide()

func _start_grab() -> void:
	if state != State.CHASE or _in_hitstun:  # No puede hacer grab durante hitstun
		return
	state = State.GRAB
	$attack.play()
	_dot_timer.start()
	_grab_timer.start(grab_duration)

func _cancel_grab() -> void:
	"""Cancela el grab actual debido a hitstun"""
	if state == State.GRAB:
		_dot_timer.stop()
		state = State.CHASE
		_grab_cd_timer.start(grab_cooldown * 0.5)  # Cooldown reducido por cancelación
		print("Grab cancelado por hitstun")

func _on_dot_tick() -> void:
	if state == State.GRAB and player and not _in_hitstun:
		player.emit_signal("damage", grab_dps * grab_tick, "veneno")
	else:
		_dot_timer.stop()

func _on_grab_timer_timeout() -> void:
	_dot_timer.stop()
	state = State.CHASE
	_grab_cd_timer.start(grab_cooldown)

func _on_grab_cd_timeout() -> void:
	pass

# ===== Colisiones de área =====
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("player_2"):
		pass
	if body.is_in_group("player_1_bullet"):
		emit_signal("damage", 30.0)
		if body.has_method("queue_free"):
			body.queue_free()
	
func _on_area_2d_body_exited(body: Node2D) -> void:
	pass

func _on_area_2d_area_entered(a: Area2D) -> void:
	if a.is_in_group("player_1_bullet"):
		emit_signal("damage", 10.0)
		if a.has_method("queue_free"):
			a.queue_free()
	if a.is_in_group("alabarda_player_2"):
		var parent = a.get_parent()
		if parent and parent.is_in_group("players"):
			emit_signal("damage", 20.0)  # Daño fijo para la alabarda
	elif a.is_in_group("puño_player_2"):
		emit_signal("damage", 20.0)
		if a.has_method("queue_free"):
			a.queue_free()

# ===== Daño/vida UI CON HITSTUN =====
func _on_damage(amount: float) -> void:
	if bar_7:
		bar_7.value = clamp(bar_7.value - amount, bar_7.min_value, bar_7.max_value)
	
	_stack_value += amount
	label.text = str(int(_stack_value))
	label.visible = true
	label.position = _label_base_pos
	label.scale = Vector2.ONE
	
	var sum := int(_stack_value)
	var col := Color(1,1,1,1)
	if sum <= 20: col = Color(1,1,1,1)
	elif sum <= 40: col = Color(1,1,0,1)
	else: col = Color(1,0,0,1)
	label.modulate = col

	if _tween and _tween.is_running():
		_tween.kill()
	var t := create_tween()
	t.tween_property(label, "position:y", _label_base_pos.y - 16.0, 0.22)
	t.parallel().tween_property(label, "scale", Vector2(1.2, 1.2), 0.16)
	t.parallel().tween_property(label, "modulate:a", 0.0, 0.32).set_delay(0.04)
	_stack_timer.start(0.4)

	# === NUEVO: SISTEMA DE HITSTUN ===
	_process_hitstun(amount)

	if not dead and bar_7 and bar_7.value <= bar_7.min_value:
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
	
	# Duración del hitstun se extiende con combos (más que otros enemigos)
	var extended_duration = hitstun_duration + (_combo_count * 0.2)  # Más extensión para enemy_5
	_hitstun_timer.start(extended_duration)
	
	print("Combo Especial x", _combo_count, " - Hitstun: ", extended_duration, "s")

func _enter_hitstun() -> void:
	if dead:
		return
		
	_in_hitstun = true
	
	# Cancelar grab si está activo
	if state == State.GRAB:
		_cancel_grab()
	
	# Para todos los timers relacionados con ataques
	if _grab_cd_timer:
		_grab_cd_timer.paused = true
	
	# Cambia color a rojo intenso con animación suave
	if _hitstun_tween:
		_hitstun_tween.kill()
	
	_hitstun_tween = create_tween()
	_hitstun_tween.tween_property(sprite_2d, "modulate", hitstun_color, 0.1)
	
	# Reducir velocidad drásticamente durante hitstun
	speed *= 0.1  # 10% de velocidad (el más severo)
	
	# Efecto de sacudida intenso para enemy especial
	_screen_shake_effect_special()
	
	# Reproducir animación de hitstun si existe
	if sprite_2d and sprite_2d.sprite_frames.has_animation("hitstun"):
		sprite_2d.play("hitstun")

func _end_hitstun() -> void:
	if not _in_hitstun:
		return
		
	_in_hitstun = false
	
	# Reactiva timers
	if _grab_cd_timer and not dead:
		_grab_cd_timer.paused = false
	
	# Restaura color original
	if _hitstun_tween:
		_hitstun_tween.kill()
	
	_hitstun_tween = create_tween()
	_hitstun_tween.tween_property(sprite_2d, "modulate", _original_color, 0.2)
	
	# Restaura velocidad (si no está en electroshock)
	if not _is_shocked:
		speed = _base_speed
	
	# Volver a animación idle
	if not dead and sprite_2d and sprite_2d.sprite_frames.has_animation("idle"):
		sprite_2d.play("idle")
	
	print("Hitstun Especial terminado")

func _reset_combo() -> void:
	if _combo_count > 1:
		print("Combo Especial terminado: ", _combo_count, " golpes!")
	_combo_count = 0

func _screen_shake_effect_special() -> void:
	# Efecto de sacudida extra intenso para enemy_5
	var shake_tween = create_tween()
	var original_pos = sprite_2d.position
	
	# Sacudida muy intensa y prolongada
	for i in range(6):  # Más sacudidas que otros enemigos
		var offset = Vector2(randf_range(-8, 8), randf_range(-8, 8))  # Más intenso
		shake_tween.tween_property(sprite_2d, "position", original_pos + offset, 0.025)
		shake_tween.tween_property(sprite_2d, "position", original_pos, 0.025)

func _on_stack_timeout() -> void:
	_stack_value = 0.0
	label.visible = false

# ===== Muerte/Explosión =====
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
	_dot_timer.stop()
	_grab_timer.stop()

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

func _on_sprite_2d_animation_finished() -> void:
	if sprite_2d.animation == "explosion":
		if explosion_timer and explosion_timer.time_left > 0.0:
			explosion_timer.stop()
		if _is_shocked:
			_end_electroshock()
		if not reported_dead:
			# Registrar eliminación
			var killer_id = _determine_killer()
			if killer_id != "":
				# KillTracker.register_kill(killer_id, "enemy_5")  # Descomentar si tienes KillTracker
				pass
			_drop_coin()
			reported_dead = true
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

func _on_explosion_timer_timeout() -> void:
	if not reported_dead:
		var killer_id = _determine_killer()
		if killer_id != "":
			# KillTracker.register_kill(killer_id, "enemy_5")  # Descomentar si tienes KillTracker
			pass
		_drop_coin()
		reported_dead = true
		emit_signal("died")
	queue_free()

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

	if not _is_shocked:
		_base_speed = speed
		_is_shocked = true
	speed = min(speed, _base_speed * factor)

	_shock_timer.start(duration)

func _end_electroshock() -> void:
	_is_shocked = false
	speed = _base_speed
