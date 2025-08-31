extends CharacterBody2D

signal damage(value: float)
signal died

var speed := 40.0
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
@export var poison_scene: PackedScene        # Asignar en el editor: PoisonCloud.tscn
@export var dash_speed := 520.0
@export var dash_time := 0.35
@export var dash_cooldown := 2.2
@export var dash_min_range := 120.0          # no dashes si está demasiado cerca
@export var dash_max_range := 520.0          # ni demasiado lejos
@export var dash_chance := 0.35              # probabilidad de decidir dash cuando puede

@export var poison_spawn_interval := 0.08    # cada cuánto deja un charco durante el dash
@export var poison_lifetime := 2.5           # se pasan a la escena veneno (si expuesto allí)
@export var poison_dps := 12.0
@export var poison_tick := 0.25

var _is_dashing := false
var _dash_dir := Vector2.ZERO
var _dash_timer: Timer
var _dash_cd_timer: Timer
var _poison_timer: Timer

@export var shock_duration: float = 1.5   # segundos de lentitud
@export var shock_factor: float   = 0.35  # 35% de la velocidad original

var _shock_timer: Timer
var _base_speed: float
var _is_shocked := false
# ===================================

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
	#---ELECTROSHOCK
	_base_speed = speed

	_shock_timer = Timer.new()
	_shock_timer.one_shot = true
	add_child(_shock_timer)
	if not _shock_timer.is_connected("timeout", Callable(self, "_end_electroshock")):
		_shock_timer.connect("timeout", Callable(self, "_end_electroshock"))
func _physics_process(delta: float) -> void:
	if dead or player == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	# --- limpiar electroshock antes de liberar ---
	if _shock_timer:
		_shock_timer.stop()
	_is_shocked = false
	speed = _base_speed
	# (opcional) revertir feedback visual:
	# if sprite_2d: sprite_2d.modulate = Color(1,1,1)
	var to_player := player.global_position - global_position
	var dist := to_player.length()
	var dir := to_player.normalized()

	walk_phase += delta
	var target_vel := Vector2.ZERO

	if _is_dashing:
		# durante dash: ir recto y dejar veneno
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
				target_vel = dir * speed + offset
			elif dist < min_range:
				target_vel = -dir * (speed * 0.8)
			else:
				target_vel = dir * (speed * 0.55) + offset * 0.4

		# intentar dash si se cumplen condiciones
		_try_dash(dist, dir)

	# clamp de velocidad
	if target_vel.length() > dash_speed and _is_dashing == false:
		target_vel = target_vel.normalized() * dash_speed
	velocity = velocity.move_toward(target_vel, accel * delta)

	rotation = 0.0
	if abs(dir.x) > 0.1:
		face_sign = sign(dir.x)
	sprite_2d.flip_h = face_sign < 0.0

	move_and_slide()

	# golpe normal si no está dashing
	if not _is_dashing and dist <= attack_range and target_in_range and punch_timer.time_left <= 0.0 and not dead:
		_do_punch(dir)

func _try_dash(dist: float, dir: Vector2) -> void:
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

func _on_area_2d_area_exited(area: Area2D) -> void:
	pass
