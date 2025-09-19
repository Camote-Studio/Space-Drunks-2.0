extends CharacterBody2D

signal damage(value: float)
signal died

# ----------------- FASES/ESTADOS -----------------
enum State { NORMAL, PHASE_85 }
var current_state: int = State.NORMAL
var _did_dash85 := false              # para no repetir el dash de 85%
# -------------------------------------------------

var speed := 80.0
var player: CharacterBody2D = null
@onready var label: Label = $Label
@onready var bar_boss: ProgressBar = $ProgressBar_boss
@onready var area: Area2D = $Area2D
@onready var sfx_hit: AudioStreamPlayer2D = $hit
@onready var explosion_timer: Timer = $explosion_timer
@onready var punch_timer: Timer = $Punch_timer
@onready var sprite_2d: AnimatedSprite2D = $Sprite2D

var min_range := 70.0
var max_range := 140.0
var attack_range := 160.0
var punch_damage := 20.0
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
var face_sign := 1.0

# ========== DASH + VENENO ==========
@export var poison_scene: PackedScene
@export var dash_speed := 520.0
@export var dash_time := 0.35
@export var dash_cooldown := 2.2
@export var dash_min_range := 120.0
@export var dash_max_range := 520.0
@export var dash_chance := 0.35

@export var poison_spawn_interval := 0.08
@export var poison_lifetime := 2.5
@export var poison_dps := 12.0
@export var poison_tick := 0.25

var _is_dashing := false
var _dash_dir := Vector2.ZERO
var _dash_timer: Timer
var _dash_cd_timer: Timer
var _poison_timer: Timer

@export var shock_duration: float = 1.5
@export var shock_factor: float   = 0.35

var _shock_timer: Timer
var _base_speed: float
var _is_shocked := false

@export var frames_face_right := false   # ponlo en false si tus sprites miran a la IZQUIERDA por defecto
const MOVE_FACE_EPS := 5.0              # umbral de movimiento en px/s para decidir facing
# ===================================
@export var dizzy_offset: Vector2 = Vector2(0, -28) # dónde dibujar el “mareo”
@export var spiral_turns: float = 2.0                 # número de vueltas
@export var spiral_spacing: float = 3.0              # separación entre “brazos” (b en r=a+bθ)
@export var spiral_points: int = 180                 # resolución (más puntos = más suave)
@export var spiral_width: float = 2.0                # grosor de la línea
# --- STUN / INTERLUDIO DE FASE ---
var _is_stunned := false
var _stun_time_left := 0.0
var _orig_modulate := Color(1,1,1,1)
var _dizzy_fx: Node2D          # contenedor del efecto
var _dizzy_radius := 18.0      # radio del “mareo” sobre la cabeza
var _dizzy_speed := 5.0        # velocidad de rotación (radianes/s aprox)
# ---------------------------------


func random_pitch_variations_gun():
	var random_pitch = pitch_variations_gun[randi()%pitch_variations_gun.size()]
	$hit.pitch_scale = random_pitch
	$hit.play()

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	add_to_group("boss")

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

	# ---- Timers del DASH/veneno ----
	_dash_timer = Timer.new(); _dash_timer.one_shot = true; add_child(_dash_timer)
	_dash_timer.connect("timeout", Callable(self, "_on_dash_timer_timeout"))
	_dash_cd_timer = Timer.new(); _dash_cd_timer.one_shot = true; add_child(_dash_cd_timer)
	_poison_timer = Timer.new(); _poison_timer.one_shot = false; add_child(_poison_timer)
	_poison_timer.wait_time = poison_spawn_interval
	_poison_timer.connect("timeout", Callable(self, "_spawn_poison_here"))

	#--- Electroshock
	_base_speed = speed
	_shock_timer = Timer.new()
	_shock_timer.one_shot = true
	add_child(_shock_timer)
	if not _shock_timer.is_connected("timeout", Callable(self, "_end_electroshock")):
		_shock_timer.connect("timeout", Callable(self, "_end_electroshock"))

	current_state = State.NORMAL
	_did_dash85 = false
	
		# Guarda color original del sprite
	if sprite_2d:
		_orig_modulate = sprite_2d.self_modulate

# Guarda color original
	if sprite_2d:
		_orig_modulate = sprite_2d.self_modulate

# FX de mareo
	_dizzy_fx = Node2D.new()
	add_child(_dizzy_fx)
	_dizzy_fx.position = dizzy_offset
	_dizzy_fx.visible = false

	var line := Line2D.new()
	line.width = 2.0
	line.default_color = Color(1, 0.9, 0.2, 1.0)
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND

	var pts := PackedVector2Array()
	var max_theta := TAU * spiral_turns
	for i in range(spiral_points + 1):
		var t := float(i) / float(spiral_points)          # 0..1
		var theta := t * max_theta                        # ángulo
		var r := spiral_spacing * theta                   # r = b·θ (a=0)
		var x := r * cos(theta)
		var y := r * sin(theta)
	# pequeño lift para que quede “encima de la cabeza”
		pts.push_back(Vector2(x, y - 8.0))
	line.points = pts

	_dizzy_fx.add_child(line)
	
	

func _physics_process(delta: float) -> void:
	if dead or player == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# reset visual shock por si lo estabas usando temporalmente
	if _shock_timer:
		_shock_timer.stop()
	_is_shocked = false
	speed = _base_speed

	# --- vector al jugador ---
	var to_player := player.global_position - global_position
	var dist := to_player.length()
	var dir := Vector2.ZERO
	if dist > 0.0:
		dir = to_player / dist


	# ---------- STATE MACHINE por vida ----------
	_update_state(dist, dir)
	# -------------------------------------------

	walk_phase += delta
	var target_vel := Vector2.ZERO

	if _is_dashing:
		target_vel = _dash_dir * dash_speed
	else:
		# movimiento normal con oscilación
		var offset := Vector2.ZERO
		if dist > max_range * 0.9:
			var phase := walk_phase * TAU
			offset = Vector2(
				sin(phase * walk_freq + walk_seed) * side_amp,
				sin(phase * up_freq + walk_seed * 0.73) * up_amp
			)
		if _attack_lock:
			target_vel = Vector2.ZERO
		else:
			if dist > max_range:
				target_vel = dir * speed 
			elif dist < min_range:
				target_vel = -dir * (speed * 0.8)
			else:
				target_vel = Vector2.ZERO

		# Dash “normal” por probabilidad y rango
		_try_dash(dist, dir)

	# clamp de velocidad
	if target_vel.length() > dash_speed and _is_dashing == false:
		target_vel = target_vel.normalized() * dash_speed

	velocity = velocity.move_toward(target_vel, accel * delta)

	rotation = 0.0
	# ---- FACING ROBUSTO ----
	var face_dir := face_sign

# a) Si te mueves (por velocity) o estás en dash, usa eso para mirar
	var moving_x = abs(velocity.x) > MOVE_FACE_EPS or (_is_dashing and abs(_dash_dir.x) > 0.01)
	if moving_x:
		var sx := 0.0
		if _is_dashing:
			sx = sign(_dash_dir.x)
		else:
			sx = sign(velocity.x)
		if sx != 0:
			face_dir = sx
# b) Si no te mueves, mira hacia el jugador (si hay diferencia apreciable)
	elif player and abs(player.global_position.x - global_position.x) > 2.0:
		face_dir = sign(player.global_position.x - global_position.x)
	face_sign = face_dir

# c) Aplica flip según orientación por defecto de tus frames
	if frames_face_right:
		sprite_2d.flip_h = face_sign < 0.0   # frames miran a la DERECHA por defecto
	else:
		sprite_2d.flip_h = face_sign > 0.0   # frames miran a la IZQUIERDA por defecto
# ------------------------


	move_and_slide()

	# golpe normal si no está dashing
	if not _is_dashing and dist <= attack_range and target_in_range and punch_timer.time_left <= 0.0 and not dead:
		_do_punch(dir)
# --- manejo de STUN ---
	if _is_stunned:
	# quieto
		velocity = Vector2.ZERO
		move_and_slide()

	# actualiza timer y rota el “mareo”
		_stun_time_left -= delta
		if _dizzy_fx:
			_dizzy_fx.rotation += _dizzy_speed * delta
			var s := 1.0 + 0.06 * sin(Time.get_ticks_msec() / 100.0)
			_dizzy_fx.scale = Vector2(s, s)
	if _stun_time_left <= 0.0:
		_end_stun()
	return
# -----------------------

# ---------- Helpers de estado ----------
func _hp_pct() -> float:
	if bar_boss == null:
		return 1.0
	var minv := bar_boss.min_value
	var maxv := bar_boss.max_value
	if maxv <= minv:
		return 1.0
	return (bar_boss.value - minv) / (maxv - minv)

func _update_state(dist: float, dir: Vector2) -> void:
	match current_state:
		State.NORMAL:
			if _hp_pct() <= 0.85 and not _did_dash85:
				current_state = State.PHASE_85
				_did_dash85 = true
				_enter_stun(3.0) # <- interludio de fase
		State.PHASE_85:
			dash_chance = 0.6
			speed = max(speed, _base_speed * 1.15)
			accel = max(accel, 1800.0)

# --------------------------------------

func _try_dash(dist: float, dir: Vector2) -> void:
	if current_state == State.NORMAL:
		return
	if _is_dashing or _attack_lock:
		return
	if _dash_cd_timer.time_left > 0.0:
		return
	if dist < dash_min_range or dist > dash_max_range:
		return
	if rng.randf() > dash_chance:
		return
	_start_dash(dir)

func _start_dash(dir: Vector2) -> void:
	_is_dashing = true
	_attack_lock = true
	_dash_dir = dir
	_poison_timer.start()
	_dash_timer.start(dash_time)

func _on_dash_timer_timeout() -> void:
	_is_dashing = false
	_attack_lock = false
	_poison_timer.stop()
	_dash_cd_timer.start(dash_cooldown)

func _spawn_poison_here() -> void:
	if poison_scene == null:
		return
	var p := poison_scene.instantiate()
	if p == null:
		return
	if p.has_method("setup"):
		p.call("setup", poison_lifetime, poison_dps, poison_tick)
	get_parent().add_child(p)
	p.global_position = global_position

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("player_2"):
		target_in_range = body as CharacterBody2D
	if body.is_in_group("player_1_bullet"):
		emit_signal("damage", 20.0)
		if body.has_method("queue_free"):
			body.queue_free()
	elif body.is_in_group("puño_player_2"):
		emit_signal("damage", 20.0)
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
	if a.is_in_group("puño_player_2"):
		emit_signal("damage", 10.0)
		if a.has_method("queue_free"):
			a.queue_free()

func _do_punch(dir: Vector2) -> void:
	if target_in_range:
		target_in_range.emit_signal("damage", punch_damage)
		if sfx_hit:
			sfx_hit.pitch_scale = pitch_variations[rng.randi_range(0, pitch_variations.size() - 1)]
			sfx_hit.play()
	_attack_lock = true
	if _tween and _tween.is_running():
		_tween.kill()
	var start := global_position
	var end := start + dir * lunge_dist
	_tween = create_tween()
	_tween.tween_property(self, "global_position", end, lunge_time)
	_tween.tween_property(self, "global_position", start, lunge_time)
	punch_timer.start(punch_cooldown)

func _on_punch_timer_timeout() -> void:
	_attack_lock = false

func _on_damage(amount: float) -> void:
	if bar_boss:
		bar_boss.value = clamp(bar_boss.value - amount, bar_boss.min_value, bar_boss.max_value)

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

	# Si llega a 0, muere
	if not dead and bar_boss and bar_boss.value <= bar_boss.min_value:
		_die()

func _on_stack_timeout() -> void:
	_stack_value = 0.0
	label.visible = false

func _die() -> void:
	dead = true
	label.visible = false
	velocity = Vector2.ZERO
	area.set_deferred("monitoring", false)
	punch_timer.stop()
	_poison_timer.stop()
	_dash_timer.stop()
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
		if not reported_dead:
			reported_dead = true
			emit_signal("died")
		queue_free()
func _on_explosion_timer_timeout() -> void:
	if not reported_dead:
		reported_dead = true
		emit_signal("died")
	queue_free()
func _enter_stun(duration: float) -> void:
	# Cancela acciones en curso
	_is_stunned = true
	_stun_time_left = duration
	velocity = Vector2.ZERO
	_attack_lock = true
	_is_dashing = false
	_poison_timer.stop()
	_dash_timer.stop()

	# Apariencia (rojo) + FX activado
	if sprite_2d:
		sprite_2d.self_modulate = Color(1.0, 0.35, 0.35, 1.0)
	if _dizzy_fx:
		_dizzy_fx.visible = true
		_dizzy_fx.rotation = 0.0

func _end_stun() -> void:
	_is_stunned = false
	_attack_lock = false
	_stun_time_left = 0.0
	# restaura color y oculta FX
	if sprite_2d:
		sprite_2d.self_modulate = _orig_modulate
	if _dizzy_fx:
		_dizzy_fx.visible = false
