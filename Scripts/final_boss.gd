extends CharacterBody2D

signal damage(value: float)
signal died

# ---------- MOVIMIENTO / LOOK ----------
var speed := 40.0
var accel := 1600.0
var face_sign := 1.0
@export var frames_face_right := true     # true si los frames miran a la DERECHA por defecto
@export var default_anim := "idle"        # animación con la que arranca el boss

# ---------- TARGET / UI / AUDIO ----------
var player: CharacterBody2D = null
@onready var label: Label = $Label
@onready var area: Area2D = $Area2D
@onready var sfx_hit: AudioStreamPlayer2D = $hit
@onready var punch_timer: Timer = $Punch_timer
@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var bar_boss: TextureProgressBar = $"../CanvasLayer/ProgressBar_boss"

# ---------- RANGOS / ATAQUE ----------
var min_range := 70.0
var max_range := 140.0
var attack_range := 160.0
var punch_damage := 20.0
var punch_cooldown := 0.6
var lunge_dist := 38.0
var lunge_time := 0.12

# ---------- CAMINATA / OSCILACION ----------
var side_amp := 20.0
var up_amp := 10.0
var walk_freq := 1.4
var up_freq := 1.8
var walk_phase := 0.0
var walk_seed := 0.0

# ---------- STACK / TWEENS ----------
var _stack_value := 0.0
var _label_base_pos := Vector2.ZERO
var _tween: Tween
var _stack_timer: Timer

# ---------- ESTADO VIDA ----------
var dead := false
var reported_dead := false
var target_in_range: CharacterBody2D = null
var rng := RandomNumberGenerator.new()
var pitch_variations := [0.9, 1.1, 1.3]
var pitch_variations_gun = [0.8, 1.5, 2.5]
var _attack_lock := false

# ========== DASH + VENENO ==========
@export var dash_speed := 520.0
@export var dash_time := 0.35
@export var dash_cooldown := 2.2
@export var dash_max_range := 520.0
@export var dash_trigger_dist := 300.0

@export var poison_scene: PackedScene
@export var poison_spawn_interval := 0.08
@export var poison_lifetime := 2.5
@export var poison_dps := 12.0
@export var poison_tick := 0.25

var _is_dashing := false
var _dash_dir := Vector2.ZERO
var _dash_timer: Timer
var _dash_cd_timer: Timer
var _poison_timer: Timer

# --- Shock placeholder ---
@export var shock_duration: float = 1.5
@export var shock_factor: float   = 0.35
var _shock_timer: Timer
var _base_speed: float
var _is_shocked := false

# ========== SHOOTING ==========
@export var bullet_scene: PackedScene = preload("res://Scenes/Enemies/Jefes/Jefe_Pulpo/Ataques/boss_bullet.tscn")
@export var shoot_interval_min := 1.6
@export var shoot_interval_max := 2.8
@export var shoot_windup := 0.35
@export var shoot_recovery := 0.25
@export var bullet_speed := 380.0
@export var bullet_lifetime := 3.0
@export var bullet_damage := 12.0
@export var muzzle_offset := Vector2(20, -6)
@export var shoot_min_dist := 600.0

var _is_shooting := false
var _shoot_timer: Timer
var _shoot_cd_timer: Timer
var _shoot_next_time := 0.0

# ========== FASES ==========
enum Phase { NORMAL, PHASE_85, PHASE_55, PHASE_25 }
var current_phase: int = Phase.NORMAL
var _did_phase_85 := false
var _did_phase_55 := false
var _did_phase_25 := false

# ========== STUN + ESPIRAL ==========
@export var stun_duration := 3.0
@export var dizzy_offset: Vector2 = Vector2(0, -28)
@export var spiral_turns: float = 2.0
@export var spiral_spacing: float = 3.0
@export var spiral_points: int = 180
@export var spiral_width: float = 2.0
var _dizzy_fx: Node2D
var _dizzy_speed := 5.0
var _is_stunned := false
var _stun_time_left := 0.0

# ---------- COLORES ----------
var _base_modulate := Color(1,1,1,1)

# ------------------------------------------------------------

func random_pitch_variations_gun():
	var random_pitch = pitch_variations_gun[randi() % pitch_variations_gun.size()]
	$hit.pitch_scale = random_pitch
	$hit.play()

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0: player = players[0]
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

	_stack_timer = Timer.new(); _stack_timer.one_shot = true; add_child(_stack_timer)
	_stack_timer.connect("timeout", Callable(self, "_on_stack_timeout"))

	if sprite_2d and not sprite_2d.is_connected("animation_finished", Callable(self, "_on_sprite_2d_animation_finished")):
		sprite_2d.connect("animation_finished", Callable(self, "_on_sprite_2d_animation_finished"))
	if not is_connected("damage", Callable(self, "_on_damage")):
		connect("damage", Callable(self, "_on_damage"))

	# Dash / veneno
	_dash_timer = Timer.new(); _dash_timer.one_shot = true; add_child(_dash_timer)
	_dash_timer.connect("timeout", Callable(self, "_on_dash_timer_timeout"))
	_dash_cd_timer = Timer.new(); _dash_cd_timer.one_shot = true; add_child(_dash_cd_timer)
	_poison_timer = Timer.new(); _poison_timer.one_shot = false; add_child(_poison_timer)
	_poison_timer.wait_time = poison_spawn_interval
	_poison_timer.connect("timeout", Callable(self, "_spawn_poison_here"))

	# Shock placeholder
	_base_speed = speed
	_shock_timer = Timer.new(); _shock_timer.one_shot = true; add_child(_shock_timer)
	if not _shock_timer.is_connected("timeout", Callable(self, "_end_electroshock")):
		_shock_timer.connect("timeout", Callable(self, "_end_electroshock"))

	# Shooting
	_shoot_timer = Timer.new(); _shoot_timer.one_shot = true; add_child(_shoot_timer)
	_shoot_timer.connect("timeout", Callable(self, "_on_shoot_timer_timeout"))
	_shoot_cd_timer = Timer.new(); _shoot_cd_timer.one_shot = true; add_child(_shoot_cd_timer)
	_shoot_cd_timer.connect("timeout", Callable(self, "_on_shoot_cd_timeout"))
	_shoot_next_time = rng.randf_range(shoot_interval_min, shoot_interval_max)
	_shoot_cd_timer.start(_shoot_next_time)

	# FX espiral
	_create_dizzy_fx()

	# Animación por defecto al arrancar
	_play_default_anim()

# ---------- Default anim ----------
func _play_default_anim() -> void:
	if not sprite_2d:
		return
	sprite_2d.self_modulate = _base_modulate
	face_sign = 1.0
	# Queremos mirar a la derecha al inicio:
	if frames_face_right:
		sprite_2d.flip_h = false
	else:
		sprite_2d.flip_h = true
	# anim por defecto o la primera disponible
	var anim := default_anim
	if not sprite_2d.sprite_frames or not sprite_2d.sprite_frames.has_animation(anim):
		var names := sprite_2d.sprite_frames.get_animation_names()
		if names.size() > 0:
			anim = names[0]
	sprite_2d.play(anim)
	sprite_2d.frame = 0

# ------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# objetivo actual: jugador más cercano
	var target := _best_target()
	if target == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_update_phase()

	# STUN
	if _is_stunned:
		velocity = Vector2.ZERO
		move_and_slide()
		_stun_time_left -= delta
		if _dizzy_fx:
			_dizzy_fx.rotation += _dizzy_speed * delta
		if _stun_time_left <= 0.0:
			_end_stun()
		return

	# limpiar shock
	if _shock_timer: _shock_timer.stop()
	_is_shocked = false
	speed = _base_speed

	# vector al objetivo
	var to_target := target.global_position - global_position
	var dist := to_target.length()
	var dir := Vector2.ZERO
	if dist > 0.0:
		dir = to_target / dist

	walk_phase += delta
	var target_vel := Vector2.ZERO

	if _is_dashing:
		target_vel = _dash_dir * dash_speed
	else:
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
				target_vel = dir * speed + offset
			elif dist < min_range:
				target_vel = -dir * (speed * 0.8)
			else:
				target_vel = dir * (speed * 0.55) + offset * 0.4

		# DASH (>= 300 y <= max)
		if not _is_dashing and not _attack_lock and dist >= dash_trigger_dist and dist <= dash_max_range:
			_try_dash(dist, dir)

		# DISPARO (>= 600, cd listo)
		if not _is_dashing and not _attack_lock and dist >= shoot_min_dist and _shoot_cd_timer.time_left <= 0.0:
			_try_shoot(dist, dir)

	# mover
	if target_vel.length() > dash_speed and not _is_dashing:
		target_vel = target_vel.normalized() * dash_speed
	velocity = velocity.move_toward(target_vel, accel * delta)

	# FACING: mira siempre al objetivo por X
	var dx := target.global_position.x - global_position.x
	if abs(dx) > 1.0:
		face_sign = sign(dx)

	if frames_face_right:
		sprite_2d.flip_h = face_sign < 0.0
	else:
		sprite_2d.flip_h = face_sign > 0.0

	move_and_slide()

	# MELEE
	if not _is_dashing and dist <= attack_range and target_in_range and punch_timer.time_left <= 0.0 and not dead and not _attack_lock:
		_do_punch(dir)

# ======================= FASES =========================
func _hp_pct() -> float:
	if bar_boss == null: return 1.0
	var minv := bar_boss.min_value
	var maxv := bar_boss.max_value
	if maxv <= minv: return 1.0
	return (bar_boss.value - minv) / (maxv - minv)

func _update_phase() -> void:
	var hp := _hp_pct()
	match current_phase:
		Phase.NORMAL:
			if hp <= 0.85 and not _did_phase_85:
				current_phase = Phase.PHASE_85
				_did_phase_85 = true
				_on_phase_enter(0.85)
		Phase.PHASE_85:
			if hp <= 0.55 and not _did_phase_55:
				current_phase = Phase.PHASE_55
				_did_phase_55 = true
				_on_phase_enter(0.55)
		Phase.PHASE_55:
			if hp <= 0.25 and not _did_phase_25:
				current_phase = Phase.PHASE_25
				_did_phase_25 = true
				_on_phase_enter(0.25)
		Phase.PHASE_25:
			pass

func _on_phase_enter(_threshold: float) -> void:
	_enter_stun(stun_duration)

# ===================== STUN / ESPIRAL ==================
func _enter_stun(duration: float) -> void:
	_is_stunned = true
	_stun_time_left = duration
	_attack_lock = true
	_is_dashing = false
	velocity = Vector2.ZERO
	if _poison_timer: _poison_timer.stop()
	if _dash_timer: _dash_timer.stop()
	if sprite_2d: sprite_2d.self_modulate = Color(1.0, 0.35, 0.35, 1.0)
	if _dizzy_fx:
		_dizzy_fx.visible = true
		_dizzy_fx.rotation = 0.0

func _end_stun() -> void:
	_is_stunned = false
	_attack_lock = false
	_stun_time_left = 0.0
	if sprite_2d: sprite_2d.self_modulate = _base_modulate
	if _dizzy_fx: _dizzy_fx.visible = false

func _create_dizzy_fx() -> void:
	_dizzy_fx = Node2D.new()
	add_child(_dizzy_fx)
	_dizzy_fx.position = dizzy_offset
	_dizzy_fx.visible = false

	var line := Line2D.new()
	line.width = spiral_width
	line.default_color = Color(1, 0.9, 0.2, 1.0)
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND

	var pts := PackedVector2Array()
	var max_theta := TAU * spiral_turns
	for i in range(spiral_points + 1):
		var t := float(i) / float(spiral_points)
		var theta := t * max_theta
		var r := spiral_spacing * theta
		var x := r * cos(theta)
		var y := r * sin(theta)
		pts.push_back(Vector2(x, y - 8.0))
	line.points = pts
	_dizzy_fx.add_child(line)

# ===================== DASH ============================
func _try_dash(dist: float, dir: Vector2) -> void:
	if _is_dashing or _attack_lock: return
	if dist < dash_trigger_dist or dist > dash_max_range: return
	if rng.randf() > 0.55: return
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
	if poison_scene == null: return
	var p := poison_scene.instantiate()
	if p == null: return
	if p.has_method("setup"):
		p.call("setup", poison_lifetime, poison_dps, poison_tick)
	get_parent().add_child(p)
	p.global_position = global_position

# ===================== SHOOTING ========================
func _try_shoot(_dist: float, dir: Vector2) -> void:
	if _is_shooting or _attack_lock or _is_stunned: return
	_start_shoot(dir)

func _start_shoot(dir: Vector2) -> void:
	_is_shooting = true
	_attack_lock = true
	velocity = Vector2.ZERO
	if abs(dir.x) > 0.01:
		face_sign = sign(dir.x)
	if sprite_2d:
		sprite_2d.self_modulate = Color(0.45, 0.65, 1.0, 1.0) # azul
	_shoot_timer.start(shoot_windup)

func _on_shoot_timer_timeout() -> void:
	_fire_bullet()
	if _shoot_timer.is_connected("timeout", Callable(self, "_on_shoot_timer_timeout")):
		_shoot_timer.disconnect("timeout", Callable(self, "_on_shoot_timer_timeout"))
	_shoot_timer.connect("timeout", Callable(self, "_end_shoot"), CONNECT_ONE_SHOT)
	_shoot_timer.start(shoot_recovery)

func _end_shoot() -> void:
	_is_shooting = false
	_attack_lock = false
	if sprite_2d: sprite_2d.self_modulate = _base_modulate
	_shoot_next_time = rng.randf_range(shoot_interval_min, shoot_interval_max)
	_shoot_cd_timer.start(_shoot_next_time)
	if _shoot_timer.is_connected("timeout", Callable(self, "_end_shoot")):
		_shoot_timer.disconnect("timeout", Callable(self, "_end_shoot"))
	if not _shoot_timer.is_connected("timeout", Callable(self, "_on_shoot_timer_timeout")):
		_shoot_timer.connect("timeout", Callable(self, "_on_shoot_timer_timeout"))

func _on_shoot_cd_timeout() -> void:
	pass

func _fire_bullet() -> void:
	var target := _best_target()
	if bullet_scene == null or target == null:
		return

	var muzzle := muzzle_offset
	if sprite_2d and sprite_2d.flip_h:
		muzzle.x = -abs(muzzle.x)
	else:
		muzzle.x = abs(muzzle.x)
	var muzzle_global := global_position + muzzle

	var dir := target.global_position - muzzle_global
	var dlen := dir.length()
	if dlen <= 0.0001:
		return
	dir = dir / dlen
	var ang := atan2(dir.y, dir.x)

	var bullet := bullet_scene.instantiate()
	if bullet == null:
		return

	get_parent().add_child(bullet)
	bullet.global_position = muzzle_global
	bullet.global_rotation = ang

	if bullet.has_method("setup"):
		bullet.call("setup", dir, bullet_speed, bullet_lifetime, bullet_damage)
	elif "velocity" in bullet:
		bullet.velocity = dir * bullet_speed
	elif "direction" in bullet and "speed" in bullet:
		bullet.direction = dir
		bullet.speed = bullet_speed
	elif bullet is RigidBody2D:
		bullet.apply_impulse(dir * bullet_speed)

	if not bullet.has_node("AutoKill"):
		var kill := Timer.new()
		kill.name = "AutoKill"
		kill.one_shot = true
		kill.wait_time = bullet_lifetime
		bullet.add_child(kill)
		kill.connect("timeout", func():
			if is_instance_valid(bullet):
				bullet.queue_free()
		)
		kill.start()

# ===================== MELEE ===========================
func _do_punch(dir: Vector2) -> void:
	if target_in_range:
		target_in_range.emit_signal("damage", punch_damage)
		if sfx_hit:
			sfx_hit.pitch_scale = pitch_variations[rng.randi_range(0, pitch_variations.size() - 1)]
			sfx_hit.play()
	_attack_lock = true
	if _tween and _tween.is_running(): _tween.kill()
	var start := global_position
	var end := start + dir * lunge_dist
	_tween = create_tween()
	_tween.tween_property(self, "global_position", end, lunge_time)
	_tween.tween_property(self, "global_position", start, lunge_time)
	punch_timer.start(punch_cooldown)

func _on_punch_timer_timeout() -> void:
	_attack_lock = false

# ===================== SENSE ===========================
func _on_area_2d_body_entered(body: Node2D) -> void:
	# Marca target cercano (para melee)
	if body.is_in_group("player") or body.is_in_group("player_2"):
		target_in_range = body as CharacterBody2D

	# Daño por puños/áreas de Player 2 (ajusta grupos si usas otros)
	if body.is_in_group("puño_player_2") or body.is_in_group("golpe_player_2"):
		emit_signal("damage", 20.0)

	# Balas de jugadores
	if body.is_in_group("player_1_bullet") or body.is_in_group("player_2_bullet"):
		emit_signal("damage", 10.0)
		if body.has_method("queue_free"): body.queue_free()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == target_in_range:
		target_in_range = null

func _on_area_2d_area_entered(a: Area2D) -> void:
	# Por si los golpes/balas llegan como Area2D
	if a.is_in_group("puño_player_2") or a.is_in_group("golpe_player_2"):
		emit_signal("damage", 20.0)
	if a.is_in_group("player_1_bullet") or a.is_in_group("player_2_bullet"):
		emit_signal("damage", 10.0)
		if a.has_method("queue_free"): a.queue_free()

# ===================== DAMAGE / DEATH ==================
func _on_damage(amount: float) -> void:
	if bar_boss:
		bar_boss.value = clamp(bar_boss.value - amount, bar_boss.min_value, bar_boss.max_value)

	_stack_value += amount
	label.text = str(int(_stack_value))
	label.visible = true
	label.position = _label_base_pos
	label.scale = Vector2.ONE

	var sum := int(_stack_value)
	var col := Color(1,1,1,1)
	if sum > 40: col = Color(1,0,0,1)
	elif sum > 20: col = Color(1,1,0,1)
	label.modulate = col

	if _tween and _tween.is_running() and not _attack_lock: _tween.kill()
	var t := create_tween()
	t.tween_property(label, "position:y", _label_base_pos.y - 16.0, 0.22)
	t.parallel().tween_property(label, "scale", Vector2(1.2, 1.2), 0.16)
	t.parallel().tween_property(label, "modulate:a", 0.0, 0.32).set_delay(0.04)
	_stack_timer.start(0.4)
	random_pitch_variations_gun()

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
	if punch_timer: punch_timer.stop()
	if _poison_timer: _poison_timer.stop()
	if _dash_timer: _dash_timer.stop()
	var col := get_node_or_null("CollisionShape2D")
	if col: col.set_deferred("disabled", true)

	# Mantener animación "death" hasta terminar
	if sprite_2d and sprite_2d.sprite_frames and sprite_2d.sprite_frames.has_animation("death"):
		sprite_2d.sprite_frames.set_animation_loop("death", false)
		sprite_2d.frame = 0
		sprite_2d.play("death")
	else:
		if not reported_dead:
			reported_dead = true
			emit_signal("died")
		queue_free()

func _on_sprite_2d_animation_finished() -> void:
	if sprite_2d.animation == "death":
		if not reported_dead:
			reported_dead = true
			emit_signal("died")
		queue_free()

# ===================== SHOCK END =======================
func _end_electroshock() -> void:
	_is_shocked = false
	speed = _base_speed
	if sprite_2d:
		sprite_2d.self_modulate = _base_modulate

# ===================== HELPERS ========================
func _best_target() -> Node2D:
	var candidates: Array = []
	candidates.append_array(get_tree().get_nodes_in_group("player"))
	candidates.append_array(get_tree().get_nodes_in_group("player_2"))
	var best: Node2D = null
	var best_d2 := INF
	for c in candidates:
		if c is Node2D and is_instance_valid(c):
			var d2 := global_position.distance_squared_to(c.global_position)
			if d2 < best_d2:
				best_d2 = d2; best = c
	return best
