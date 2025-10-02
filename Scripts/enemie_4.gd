extends CharacterBody2D

signal damage(value: float)
signal died
const MONEDA = preload("res://Scenes/moneda.tscn")

var speed := 150.0
var player: CharacterBody2D = null
@onready var label: Label = $Label
@onready var bar_6: ProgressBar = $ProgressBar_enemy_4
@onready var area: Area2D = $Area2D
@onready var sfx_hit: AudioStreamPlayer2D = $hit
@onready var explosion_timer: Timer = $explosion_timer
@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var audio_laser: AudioStreamPlayer2D = $lasergun

const BULLET_ENEMY_1 := preload("res://Scenes/gun_enemy_2.tscn")

# "Anillo" de distancias (huye si está muy cerca, se acerca suave si está lejos)
var min_range := 70.0
var max_range := 140.0

# Disparo (separado del "punch")
var shoot_range := 520.0  # dispara solo si el jugador está a esta distancia o menos

# (Punch desactivado, pero dejo los valores por si luego lo reactivas)
var attack_range := 99999.0
var punch_damage := 10.0
var punch_cooldown := 0.6
var lunge_dist := 38.0
var lunge_time := 0.12

# Movimiento de suelo sin "flotar"
var accel := 1600.0
var strafe_speed := 80.0
var walk_phase := 0.0
var walk_freq := 1.2

# UI daño
var _stack_value := 0.0
var _label_base_pos := Vector2.ZERO
var _tween: Tween
var _stack_timer: Timer

# Estado
var dead := false
var reported_dead := false
var target_in_range: CharacterBody2D = null
var rng := RandomNumberGenerator.new()
var pitch_variations := [0.9, 1.1, 1.3]
var _attack_lock := false
var pitch_variations_gun := [0.8, 1.5, 2.5]
var face_sign := 1.0

@export var shock_duration: float = 1.5
@export var shock_factor: float = 0.35

var _shock_timer: Timer
var _base_speed: float
var _is_shocked := false

# === SISTEMA DE HITSTUN ===
@export var hitstun_duration: float = 0.9        # Duración intermedia para ranged
@export var hitstun_threshold: float = 15.0      # Daño mínimo para activar hitstun
@export var combo_window: float = 1.3            # Ventana de combo
@export var hitstun_color: Color = Color(1.0, 0.4, 0.4, 1.0)  # Rojo intermedio

var _in_hitstun := false
var _hitstun_timer: Timer
var _combo_timer: Timer
var _combo_count := 0
var _original_color: Color
var _hitstun_tween: Tween

func random_pitch_variations_gun():
	var random_pitch = pitch_variations_gun[randi() % pitch_variations_gun.size()]
	$hit.pitch_scale = random_pitch
	$hit.play()

func _ready() -> void:
	if bar_6:
		bar_6.min_value = 0
		bar_6.max_value = 100  
		bar_6.value = bar_6.max_value
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	add_to_group("enemy_4")

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

	_stack_timer = Timer.new()
	_stack_timer.one_shot = true
	add_child(_stack_timer)
	_stack_timer.connect("timeout", Callable(self, "_on_stack_timeout"))

	if sprite_2d and not sprite_2d.is_connected("animation_finished", Callable(self, "_on_sprite_2d_animation_finished")):
		sprite_2d.connect("animation_finished", Callable(self, "_on_sprite_2d_animation_finished"))

	if not is_connected("damage", Callable(self, "_on_damage")):
		connect("damage", Callable(self, "_on_damage"))

	# Disparo: arranca el timer si existe
	if has_node("gun_timer"):
		$gun_timer.start()
		
	# ELECTROSHOCK
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

	# === MODIFICACIÓN: Movimiento reducido durante hitstun ===
	var movement_multiplier = 1.0
	if _in_hitstun:
		movement_multiplier = 0.3  # 30% velocidad durante hitstun (intermedio para ranged)

	var target_vel: Vector2 = Vector2.ZERO
	# Lateral suave (strafe) solo en X, para que no "flote"
	var strafe: float = sin(walk_phase * TAU * walk_freq) * strafe_speed * movement_multiplier
	walk_phase += delta

	if dist < min_range:
		target_vel = -dir * speed * movement_multiplier                         # huye
	elif dist > max_range:
		target_vel = dir * (speed * 0.5) * movement_multiplier                  # se acerca suave
	else:
		target_vel = Vector2(strafe, 0.0)                 # en rango: strafe

	if target_vel.length() > speed * movement_multiplier:
		target_vel = target_vel.normalized() * speed * movement_multiplier
	velocity = velocity.move_toward(target_vel, accel * delta)

	rotation = 0.0
	# Flip según movimiento real en X (o dirección si casi parado)
	if abs(velocity.x) > 2.0:
		face_sign = sign(velocity.x)
	elif abs(dir.x) > 0.1:
		face_sign = sign(dir.x)
	sprite_2d.flip_h = face_sign < 0.0

	move_and_slide()

# === DISPARO CON HITSTUN ===
func _on_gun_timer_timeout() -> void:
	_update_target() 
	if dead or player == null:
		return
		
	# === MODIFICACIÓN: No disparar durante hitstun ===
	if _in_hitstun:
		return
		
	var to_player := player.global_position - global_position
	if to_player.length() > shoot_range:
		return

	var bullet_instance = BULLET_ENEMY_1.instantiate()
	get_parent().add_child(bullet_instance)
	bullet_instance.global_position = global_position
	bullet_instance.rotation = to_player.angle()

	# Reproducir sonido láser
	if audio_laser:
		audio_laser.stop()
		audio_laser.play()

# === Colisiones/daño CON HITSTUN ===
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("player_2"):
		target_in_range = body as CharacterBody2D
	if body.is_in_group("player_1_bullet"):
		emit_signal("damage", 10.0)
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

# === HUD de daño / muerte CON HITSTUN ===
func _on_damage(amount: float) -> void:
	if bar_6:
		bar_6.value = clamp(bar_6.value - amount, bar_6.min_value, bar_6.max_value)
		
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
	
	if _tween and _tween.is_running() and _attack_lock == false:
		_tween.kill()
	var t := create_tween()
	t.tween_property(label, "position:y", _label_base_pos.y - 16.0, 0.22)
	t.parallel().tween_property(label, "scale", Vector2(1.2, 1.2), 0.16)
	t.parallel().tween_property(label, "modulate:a", 0.0, 0.32).set_delay(0.04)
	_stack_timer.start(0.4)
	random_pitch_variations_gun()

	# === NUEVO: SISTEMA DE HITSTUN ===
	_process_hitstun(amount)

	if not dead and bar_6 and bar_6.value <= bar_6.min_value:
		$Sprite2D2.queue_free()
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
	var extended_duration = hitstun_duration + (_combo_count * 0.18)  # Extensión intermedia
	_hitstun_timer.start(extended_duration)
	

func _enter_hitstun() -> void:
	if dead:
		return
		
	_in_hitstun = true
	
	# Para el timer de disparo
	if has_node("gun_timer") and $gun_timer:
		$gun_timer.paused = true
	
	# Cambia color a rojo con animación suave
	if _hitstun_tween:
		_hitstun_tween.kill()
	
	_hitstun_tween = create_tween()
	_hitstun_tween.tween_property(sprite_2d, "modulate", hitstun_color, 0.1)
	
	# Reducir velocidad durante hitstun
	speed *= 0.3  # 30% de velocidad
	
	# Efecto de sacudida
	_screen_shake_effect_ranged()
	
	# Reproducir animación de hitstun si existe
	if sprite_2d and sprite_2d.sprite_frames.has_animation("hitstun"):
		sprite_2d.play("hitstun")

func _end_hitstun() -> void:
	if not _in_hitstun:
		return
		
	_in_hitstun = false
	
	# Reactiva disparo
	if has_node("gun_timer") and $gun_timer and not dead:
		$gun_timer.paused = false
	
	# Restaura color original
	if _hitstun_tween:
		_hitstun_tween.kill()
	
	_hitstun_tween = create_tween()
	_hitstun_tween.tween_property(sprite_2d, "modulate", _original_color, 0.18)
	
	# Restaura velocidad (si no está en electroshock)
	if not _is_shocked:
		speed = _base_speed
	
	# Volver a animación idle
	if not dead and sprite_2d and sprite_2d.sprite_frames.has_animation("idle"):
		sprite_2d.play("idle")
	

func _reset_combo() -> void:
	_combo_count = 0

func _screen_shake_effect_ranged() -> void:
	# Efecto de sacudida moderado para enemigo ranged
	var shake_tween = create_tween()
	var original_pos = sprite_2d.position
	
	# Sacudida moderada
	for i in range(4):  # 4 sacudidas
		var offset = Vector2(randf_range(-4, 4), randf_range(-4, 4))
		shake_tween.tween_property(sprite_2d, "position", original_pos + offset, 0.04)
		shake_tween.tween_property(sprite_2d, "position", original_pos, 0.04)

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
				# KillTracker.register_kill(killer_id, "enemy_4")  # Descomentar si tienes KillTracker
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
			# KillTracker.register_kill(killer_id, "enemy_4")  # Descomentar si tienes KillTracker
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
