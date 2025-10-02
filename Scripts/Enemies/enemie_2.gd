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
@onready var audio_ataque: AudioStreamPlayer2D = $ataque_golpe
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

# === SISTEMA DE HITSTUN ===
@export var hitstun_duration: float = 0.8        # Duración del hitstun por golpe
@export var hitstun_threshold: float = 15.0      # Daño mínimo para activar hitstun
@export var combo_window: float = 1.2            # Tiempo para extender combo
@export var hitstun_color: Color = Color(1.0, 0.3, 0.3, 1.0)  # Rojo para hitstun

var _in_hitstun := false
var _hitstun_timer: Timer
var _combo_timer: Timer
var _combo_count := 0
var _original_color: Color
var _hitstun_tween: Tween

# === NUEVAS VARIABLES ===
var random_move_dir := Vector2.ZERO
var random_move_timer: Timer
var random_move_chance := 0.1   # 10% probabilidad de moverse aleatorio mientras persigue
var random_move_duration := 0.8 # cuánto dura el movimiento aleatorio
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
		
	_ready_hitstun_system()
		# Timer para cambiar movimiento aleatorio
	random_move_timer = Timer.new()
	random_move_timer.one_shot = true
	add_child(random_move_timer)
	random_move_timer.connect("timeout", Callable(self, "_end_random_move"))


func _update_target() -> void:
	# Actualiza la referencia al jugador más cercano (grupos "player" y "player_2")
	var players := []
	players += get_tree().get_nodes_in_group("player")
	players += get_tree().get_nodes_in_group("player_2")
	var nearest: CharacterBody2D = null
	var nearest_dist := INF
	for p in players:
		if p and p is Node2D:
			var d := global_position.distance_to(p.global_position)
			if d < nearest_dist:
				nearest_dist = d
				nearest = p
	player = nearest

func _physics_process(delta: float) -> void:
	_update_target()

	# Si enemigo está muerto, no hace nada
	if dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# === CASO 1: TIENE JUGADOR DETECTADO ===
	if player != null:
		var to_player := player.global_position - global_position
		var dist := to_player.length()
		var dir := Vector2.ZERO
		if dist > 0.0:
			dir = to_player / dist
		var tangent := Vector2(-dir.y, dir.x)

		# Oscilaciones orgánicas
		walk_phase += delta
		var calm = clamp((dist - calm_end) / max(1.0, calm_start - calm_end), 0.12, 1.0)
		var offset = tangent * (sin(walk_phase * TAU * walk_freq + walk_seed) * side_amp * calm)
		offset += Vector2(0, 1) * (sin(walk_phase * TAU * up_freq + walk_seed * 0.73) * up_amp * calm)

		if _in_hitstun:
			offset *= 0.3
			calm *= 0.3

		# Desviación aleatoria pequeña
		var deviation := Vector2.ZERO
		if rng.randf() < random_move_chance:
			deviation = Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)).normalized() * 0.35

		var target_vel := Vector2.ZERO
		if not _attack_lock:
			var base_dir := dir
			var mixed := base_dir + deviation
			if mixed.length() > 0.0:
				base_dir = mixed.normalized()

			if dist > max_range:
				target_vel = base_dir * speed + offset
			elif dist < min_range:
				target_vel = base_dir * (speed * 0.15) + offset * 0.25
			else:
				target_vel = base_dir * (speed * 0.35) + offset * 0.6

			if target_vel.length() > speed:
				target_vel = target_vel.normalized() * speed

		velocity = velocity.move_toward(target_vel, accel * delta)

		if sprite_2d:
			sprite_2d.flip_h = dir.x > 0.0

		move_and_slide()

		# Intentar atacar
		if dist <= attack_range and target_in_range and punch_timer.time_left <= 0.0 and not _in_hitstun:
			_do_punch(dir)

	# === CASO 2: NO HAY JUGADOR DETECTADO (PATRULLA ALEATORIA) ===
	else:
		if random_move_dir == Vector2.ZERO and not random_move_timer.is_stopped():
			# ya está esperando al siguiente movimiento -> quedarse quieto un momento
			velocity = Vector2.ZERO
		else:
			# si no tiene dirección, iniciar movimiento aleatorio
			if random_move_dir == Vector2.ZERO:
				_start_random_move()
			velocity = random_move_dir * (speed * 0.4)  # patrulla más lento que persecución

		move_and_slide()


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
	
	# No atacar si está en hitstun
	if _in_hitstun:
		return
		
	if target_in_range:
		print("💥 Enemigo golpea al jugador con daño:", punch_damage)
		target_in_range.emit_signal("damage", punch_damage)
		# 🔊 sonido del ataque
		if audio_ataque:
			audio_ataque.stop()  # reinicia si estaba sonando
			audio_ataque.play()

			
	_attack_lock = true
	if _tween and _tween.is_running():
		_tween.kill()
		
	# Animación de golpe
	if sprite_2d and sprite_2d.sprite_frames.has_animation("golpe"):
		sprite_2d.play("golpe")
		
	# Movimiento de embestida (si no está en hitstun)
	if not _in_hitstun:
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
	
	# === NUEVO: SISTEMA DE HITSTUN ===
	_process_hitstun(amount)

	if not dead and bar_4 and bar_4.value <= bar_4.min_value:
		_die()

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
			_drop_coin()              # 💰 primero soltar moneda
			reported_dead = true      # luego marcar muerte reportada
			emit_signal("died")
		queue_free()


func _on_explosion_timer_timeout() -> void:
	if not reported_dead:
		_drop_coin()                 # 💰 soltar moneda también aquí
		reported_dead = true
		emit_signal("died")
	queue_free()

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
	
# === SISTEMA DE HITSTUN PARA ENEMY 2 ===
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
		
# === FUNCIONES DEL HITSTUN ===
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
	
	# Duración del hitstun se extiende con combos (menos que el ranged)
	var extended_duration = hitstun_duration + (_combo_count * 0.15)  # Menos extensión para melee
	_hitstun_timer.start(extended_duration)
	
	print("🥊 Combo Melee x", _combo_count, " - Hitstun: ", extended_duration, "s")	
	
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
	
	# Reducir velocidad durante hitstun (más agresivo para melee)
	speed *= 0.3  # 30% de velocidad (más severo que ranged)
	
	# Efecto visual: sacudida más intensa para melee
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
	if not dead and sprite_2d and sprite_2d.sprite_frames.has_animation("Idle"):
		sprite_2d.play("Idle")
	
	print("🛡️ Hitstun Melee terminado")
	
func _cancel_current_attack() -> void:
	# Cancela ataque en progreso
	_attack_lock = false
	
	# Para cualquier tween de movimiento de ataque
	if _tween and _tween.is_running():
		_tween.kill()
		# No regresar a posición original, quedarse donde está
	
	# Para timer de ataque
	if punch_timer:
		punch_timer.stop()
		
func _reset_combo() -> void:
	if _combo_count > 1:
		print("💥 Combo Melee terminado: ", _combo_count, " golpes!")
	_combo_count = 0

func _screen_shake_effect_melee() -> void:
	# Efecto de sacudida más intensa para enemigo melee
	var shake_tween = create_tween()
	var original_pos = sprite_2d.position
	
	# Sacudida más fuerte y más golpes
	for i in range(4):  # Más sacudidas que el ranged
		var offset = Vector2(randf_range(-5, 5), randf_range(-5, 5))  # Más intenso
		shake_tween.tween_property(sprite_2d, "position", original_pos + offset, 0.04)
		shake_tween.tween_property(sprite_2d, "position", original_pos, 0.04)
func _start_random_move() -> void:
	random_move_dir = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
	random_move_timer.start(random_move_duration)

func _end_random_move() -> void:
	random_move_dir = Vector2.ZERO
	# después de quedarse quieto un poco, inicia nuevo movimiento
	_start_random_move()
