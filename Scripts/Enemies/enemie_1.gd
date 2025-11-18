extends CharacterBody2D

signal damage(value: float)
signal died
<<<<<<< HEAD
@onready var audio_laser : AudioStreamPlayer2D = $laser
var speed := 300
var player: CharacterBody2D = null
=======

@onready var audio_laser : AudioStreamPlayer2D = $laser
var speed: float = 300.0
var accel: float = 1200.0
var player: CharacterBody2D = null

>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
const BULLET_ENEMY_1 = preload("res://Scenes/Enemies/System/Weapons/gun_enemy_1.tscn")
@onready var label: Label = $Label
@onready var bar_3: ProgressBar = $ProgressBar_enemy
@onready var anim: AnimatedSprite2D = $Sprite2D
const MONEDA = preload("res://Scenes/Items/items_interectables/moneda.tscn")
<<<<<<< HEAD
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

@export var shock_duration: float = 1.5
@export var shock_factor: float   = 0.35  

var _shock_timer: Timer
var _base_speed: float
var _is_shocked := false

# === HITSTUN ===
=======

# ===== Seguimiento =====
@export var horizontal_only: bool = false        # false = mueve X e Y
@export var keep_y_strict: bool = false          # si true, fija Y del root
var _fixed_y: float = 0.0

# Banda ideal en X (standoff)
@export var min_range: float = 250.0
@export var max_range: float = 280.0
@export var deadzone: float = 8.0
var _band_mid: float = 0.0

# Control vertical (deadzone y offset visual por instancia)
@export var deadzone_y: float = 8.0
@export var y_offset_range: float = 80.0
var _disperse_bias_y: float = 0.0

# ===== Dispersión / separación =====
@export var separation_radius: float = 120.0
@export var separation_strength: float = 320.0
@export var separation_max_speed: float = 220.0
var _disperse_bias: float = 0.0                  # offset X por instancia

# ===== Fairness cerca del jugador =====
@export var fairness_proximity: float = 110.0    # distancia radial
@export var fairness_extra_deadzone: float = 24.0
@export var fairness_speed_cap: float = 180.0

# ===== Disparo =====
@export var attack_range: float = 400.0
@export var bullet_speed: float = 700.0

# ===== Asalto (hit & run temporal) =====
@export var assault_enabled: bool = true
@export var assault_interval_min: float = 2.2
@export var assault_interval_max: float = 4.0
@export var assault_windup_time: float = 0.20
@export var assault_max_duration: float = 1.2
@export var assault_charge_speed: float = 420.0
@export var assault_strike_radius: float = 90.0  # radio para golpear
@export var assault_damage: float = 15.0
@export var assault_retreat_time: float = 0.45
@export var assault_retreat_speed: float = 360.0
@export var assault_pause_shooting: bool = true

var _assault_timer: Timer
var _assault_state_timer: Timer
var _is_assaulting: bool = false
var _assault_state: int = 0   # 0=NONE, 1=WINDUP, 2=CHARGE, 3=RETREAT
var _assault_dir_vec: Vector2 = Vector2.ZERO
var _assault_elapsed: float = 0.0
var _assault_strike_done: bool = false

# ===== Feedback daño =====
var _stack_value: float = 0.0
var _stack_timer: Timer
var _label_base_pos: Vector2 = Vector2.ZERO
var _tween: Tween
var dead: bool = false
var reported_dead: bool = false

# Patrulla sin jugador
var wiggle_t: float = 0.0
var wiggle_amp: float = 40.0
var wiggle_freq: float = 1.6
var pitch_variations_gun = [0.8, 1.5, 2.5]

# ===== Electroshock =====
@export var shock_duration: float = 1.5
@export var shock_factor: float   = 0.35
var _shock_timer: Timer
var _base_speed: float
var _is_shocked: bool = false

# ===== HITSTUN =====
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
@export var hitstun_duration: float = 0.8
@export var hitstun_threshold: float = 15.0
@export var combo_window: float = 1.2
@export var hitstun_color: Color = Color(1.0, 0.3, 0.3, 1.0)
<<<<<<< HEAD

var _in_hitstun := false
var _hitstun_timer: Timer
var _combo_timer: Timer
var _combo_count := 0
var _original_color: Color
var _hitstun_tween: Tween

func random_pitch_variations_gun():
	var random_pitch = pitch_variations_gun[randi()%pitch_variations_gun.size()]
	$hit.pitch_scale = random_pitch
	$hit.play()

=======
var _in_hitstun: bool = false
var _hitstun_timer: Timer
var _combo_timer: Timer
var _combo_count: int = 0
var _original_color: Color
var _hitstun_tween: Tween

# ===== PD (flotación) =====
@export var pd_stiffness: float = 14.0
@export var pd_damping: float  = 2.2
var _pd_vx: float = 0.0
var _pd_vy: float = 0.0

# Bobbing / sway SOLO visual
@export var hover_amp_y: float = 6.0
@export var hover_freq_y: float = 2.2
@export var sway_amp_x: float  = 8.0
@export var sway_freq_x: float = 1.3
var _visual_base_pos: Vector2 = Vector2.ZERO
var _hover_t: float = 0.0

# Visual
var _facing: float = 1.0
var _spawn_pos: Vector2 = Vector2.ZERO

var rng := RandomNumberGenerator.new()


func random_pitch_variations_gun():
	var idx := randi() % pitch_variations_gun.size()
	var random_pitch = pitch_variations_gun[idx]
	$hit.pitch_scale = random_pitch
	$hit.play()


>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
<<<<<<< HEAD
	$gun_timer.start()
	add_to_group("enemy_1")
	if not is_connected("damage", Callable(self, "_on_damage")):
		connect("damage", Callable(self, "_on_damage"))
=======

	$gun_timer.start()
	add_to_group("enemy_1")

	if not is_connected("damage", Callable(self, "_on_damage")):
		connect("damage", Callable(self, "_on_damage"))

>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	_stack_timer = Timer.new()
	_stack_timer.one_shot = true
	add_child(_stack_timer)
	_stack_timer.connect("timeout", Callable(self, "_on_stack_timeout"))
<<<<<<< HEAD
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
	
	# Electroshock
=======

	_label_base_pos = label.position
	label.visible = false

	if anim and not anim.is_connected("animation_finished", Callable(self, "_on_AnimatedSprite2D_animation_finished")):
		anim.connect("animation_finished", Callable(self, "_on_AnimatedSprite2D_animation_finished"))

>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	_base_speed = speed
	_shock_timer = Timer.new()
	_shock_timer.one_shot = true
	add_child(_shock_timer)
	if not _shock_timer.is_connected("timeout", Callable(self, "_end_electroshock")):
		_shock_timer.connect("timeout", Callable(self, "_end_electroshock"))
<<<<<<< HEAD
		
	_ready_hitstun_system()

func _physics_process(delta: float) -> void:
	_update_target()
	if dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	var movement_multiplier = 1.0
	if _in_hitstun:
		movement_multiplier = 0.4
		
	if player == null:
		# === MOVIMIENTO RANDOM CUANDO NO HAY JUGADOR ===
		wiggle_t += delta
		var angle = wiggle_t * wiggle_freq
		var offset = Vector2(cos(angle), sin(angle)).normalized() * 100.0
		var patrol_vel = offset + Vector2(randf_range(-50, 50), randf_range(-50, 50))
		if patrol_vel.length() > speed * 0.6:
			patrol_vel = patrol_vel.normalized() * speed * 0.6
		velocity = velocity.move_toward(patrol_vel, accel * delta)
		move_and_slide()
		return
	
	var to_player: Vector2 = player.global_position - global_position
	var dist := to_player.length()
	look_at(player.global_position)
	rotation_degrees = wrap(rotation_degrees, 0, 360)
	
	var target_vel := Vector2.ZERO
	if dist > max_range:
		target_vel = to_player.normalized() * speed
	elif dist < min_range:
		target_vel = -to_player.normalized() * speed
	else:
		var tangent := Vector2(-to_player.y, to_player.x).normalized()
		wiggle_t += delta
		var osc := sin(wiggle_t * TAU * wiggle_freq) * wiggle_amp
		var radial := to_player.normalized() * ((desired_dist - dist) * 4.0)
		target_vel = tangent * (strafe_speed * orbit_dir + osc) + radial
		if target_vel.length() > speed:
			target_vel = target_vel.normalized() * speed
	velocity = velocity.move_toward(target_vel * movement_multiplier, accel * delta)
	move_and_slide()

func _on_strafe_swap() -> void:
	if rng.randf() < 0.7:
		orbit_dir *= -1.0
	swap_interval = rng.randf_range(1.2, 2.2)
	strafe_timer.wait_time = swap_interval

=======

	_ready_hitstun_system()

	_spawn_pos = global_position
	_fixed_y = _spawn_pos.y
	_band_mid = (min_range + max_range) * 0.5
	_lock_rotations()

	if anim:
		_visual_base_pos = anim.position

	rng.randomize()
	_disperse_bias = rng.randf_range(-180.0, 180.0)
	_disperse_bias_y = rng.randf_range(-y_offset_range, y_offset_range)

	_assault_timer = Timer.new()
	_assault_timer.one_shot = true
	add_child(_assault_timer)
	_assault_timer.connect("timeout", Callable(self, "_on_assault_timer_timeout"))

	_assault_state_timer = Timer.new()
	_assault_state_timer.one_shot = true
	add_child(_assault_state_timer)
	_assault_state_timer.connect("timeout", Callable(self, "_on_assault_state_timeout"))

	_schedule_next_assault()


func _physics_process(delta: float) -> void:
	_update_target()
	_lock_rotations()

	if dead:
		velocity = Vector2.ZERO
		if keep_y_strict:
			global_position.y = _fixed_y
		move_and_slide()
		_update_visuals(delta, 0.0)
		return

	var movement_multiplier := 1.0
	if _in_hitstun:
		movement_multiplier = 0.4

	if player == null:
		wiggle_t += delta
		var angle := wiggle_t * wiggle_freq
		var offset := Vector2(cos(angle) * 100.0, sin(angle) * 40.0)
		var patrol_vel := offset + Vector2(randf_range(-50, 50), randf_range(-20, 20))
		if patrol_vel.length() > speed * 0.6:
			patrol_vel = patrol_vel.normalized() * speed * 0.6
		velocity = velocity.move_toward(patrol_vel, accel * delta)
		if keep_y_strict:
			global_position.y = _fixed_y
		move_and_slide()
		_update_visuals(delta, velocity.x)
		return

	# ======= ASALTO (prioridad) =======
	if _is_assaulting:
		_assault_elapsed += delta

		if _assault_state == 1:
			velocity = velocity.move_toward(Vector2.ZERO, 0.25)
			if keep_y_strict:
				global_position.y = _fixed_y
			move_and_slide()
			_update_visuals(delta, _assault_dir_vec.x)
			return

		if _assault_state == 2:
			var desired := _assault_dir_vec * assault_charge_speed
			var sep := _compute_separation_v()
			desired += sep
			if desired.length() > assault_charge_speed:
				desired = desired.normalized() * assault_charge_speed
			velocity = velocity.lerp(desired, 0.35)
			if keep_y_strict:
				global_position.y = _fixed_y
				velocity.y = 0.0
			move_and_slide()
			_assault_try_strike()
			if _assault_elapsed >= assault_max_duration:
				_start_assault_retreat()
			_update_visuals(delta, _assault_dir_vec.x)
			return

		if _assault_state == 3:
			var desired_ret := (-_assault_dir_vec).normalized() * assault_retreat_speed
			var sep_ret := _compute_separation_v()
			desired_ret += sep_ret
			if desired_ret.length() > assault_retreat_speed:
				desired_ret = desired_ret.normalized() * assault_retreat_speed
			velocity = velocity.lerp(desired_ret, 0.35)
			if keep_y_strict:
				global_position.y = _fixed_y
				velocity.y = 0.0
			move_and_slide()
			_update_visuals(delta, -_assault_dir_vec.x)
			return

	# ======= Comportamiento normal =======
	var dx := player.global_position.x - global_position.x
	var target_x := player.global_position.x
	if dx < 0.0:
		target_x = player.global_position.x + _band_mid
	elif dx > 0.0:
		target_x = player.global_position.x - _band_mid
	target_x += _disperse_bias

	var target_y := player.global_position.y + _disperse_bias_y

	var to_player := player.global_position - global_position
	var dist_to_player := to_player.length()

	var local_deadzone_x := deadzone
	var local_deadzone_y := deadzone_y
	var local_speed_cap := speed

	if dist_to_player <= fairness_proximity:
		if local_deadzone_x < (deadzone + fairness_extra_deadzone):
			local_deadzone_x = deadzone + fairness_extra_deadzone
		if local_deadzone_y < (deadzone_y + fairness_extra_deadzone):
			local_deadzone_y = deadzone_y + fairness_extra_deadzone
		if local_speed_cap > fairness_speed_cap:
			local_speed_cap = fairness_speed_cap

	var ex := target_x - global_position.x
	var ey := target_y - global_position.y

	_pd_vx += (pd_stiffness * ex - pd_damping * _pd_vx) * delta
	_pd_vy += (pd_stiffness * ey - pd_damping * _pd_vy) * delta

	var desired_v := Vector2(_pd_vx, _pd_vy) * movement_multiplier

	var sep_v := _compute_separation_v()
	desired_v += sep_v

	if desired_v.length() > local_speed_cap:
		desired_v = desired_v.normalized() * local_speed_cap

	if abs(ex) <= local_deadzone_x:
		desired_v.x = lerp(desired_v.x, 0.0, 0.5)
	if abs(ey) <= local_deadzone_y:
		desired_v.y = lerp(desired_v.y, 0.0, 0.5)

	if horizontal_only:
		desired_v.y = 0.0

	velocity = desired_v

	if keep_y_strict:
		global_position.y = _fixed_y
		velocity.y = 0.0

	move_and_slide()

	var facing_hint := 0.0
	if ex < 0.0:
		facing_hint = -1.0
	elif ex > 0.0:
		facing_hint = 1.0
	_update_visuals(delta, facing_hint)


# ===== Ciclo de asalto =====
func _schedule_next_assault() -> void:
	if not assault_enabled:
		return
	if not _assault_timer:
		return
	var wait_min := assault_interval_min
	var wait_max := assault_interval_max
	if wait_max < wait_min:
		wait_max = wait_min + 0.1
	var wait_time := rng.randf_range(wait_min, wait_max)
	_assault_timer.start(wait_time)

func _on_assault_timer_timeout() -> void:
	if dead:
		return
	if not assault_enabled:
		return
	if player == null:
		_schedule_next_assault()
		return
	_start_assault()

func _start_assault() -> void:
	if _is_assaulting:
		return
	_is_assaulting = true
	_assault_state = 1
	_assault_elapsed = 0.0
	_assault_strike_done = false

	var dir := player.global_position - global_position
	if dir.length() < 0.001:
		dir = Vector2(1.0, 0.0)
	_assault_dir_vec = dir.normalized()

	if _assault_state_timer:
		_assault_state_timer.start(assault_windup_time)

func _on_assault_state_timeout() -> void:
	if _assault_state == 1:
		_assault_state = 2
		_assault_elapsed = 0.0
		return
	if _assault_state == 3:
		_end_assault()
		return

func _assault_try_strike() -> void:
	if _assault_strike_done:
		return
	var players := []
	players += get_tree().get_nodes_in_group("player")
	players += get_tree().get_nodes_in_group("player_2")

	var i := 0
	var hit := false
	while i < players.size():
		var p = players[i]
		if p:
			if p is Node2D:
				var ppos := (p as Node2D).global_position
				var d := ppos.distance_to(global_position)
				if d <= assault_strike_radius:
					if p.has_signal("damage"):
						p.emit_signal("damage", assault_damage, "embestida")
					hit = true
		i += 1

	if hit:
		_assault_strike_done = true
		_start_assault_retreat()

func _start_assault_retreat() -> void:
	_assault_state = 3
	_assault_elapsed = 0.0
	if _assault_dir_vec.length() < 0.001:
		_assault_dir_vec = Vector2(1.0, 0.0)
	if _assault_state_timer:
		_assault_state_timer.start(assault_retreat_time)

func _end_assault() -> void:
	_is_assaulting = false
	_assault_state = 0
	_assault_dir_vec = Vector2.ZERO
	_assault_elapsed = 0.0
	_assault_strike_done = false
	_schedule_next_assault()


# ===== Separación (vectorial) =====
func _compute_separation_v() -> Vector2:
	var v_sep := Vector2.ZERO
	var neighbors := get_tree().get_nodes_in_group("enemy_1")
	var i := 0
	while i < neighbors.size():
		var n = neighbors[i]
		if n != self:
			if n is Node2D:
				var np := (n as Node2D).global_position
				var diff := global_position - np
				var d := diff.length()
				if d < separation_radius:
					if d > 0.001:
						var push_norm := (separation_radius - d) / separation_radius
						var dir := diff / d
						v_sep += dir * push_norm
		i += 1

	if v_sep != Vector2.ZERO:
		v_sep = v_sep * separation_strength
		if v_sep.length() > separation_max_speed:
			v_sep = v_sep.normalized() * separation_max_speed
	return v_sep


# ===== Visuals =====
func _update_visuals(delta: float, facing_hint: float) -> void:
	if facing_hint < 0.0:
		_facing = -1.0
	elif facing_hint > 0.0:
		_facing = 1.0

	if anim:
		anim.flip_h = (_facing < 0.0)
		anim.rotation = 0.0

	_hover_t += delta
	var bob_y := 0.0
	if hover_amp_y != 0.0:
		bob_y = sin(_hover_t * TAU * hover_freq_y) * hover_amp_y
	var sway_x := 0.0
	if sway_amp_x != 0.0:
		sway_x = sin((_hover_t + 0.37) * TAU * sway_freq_x) * sway_amp_x
	if anim:
		anim.position = _visual_base_pos + Vector2(sway_x, bob_y)
	rotation = 0.0

func _lock_rotations() -> void:
	rotation = 0.0
	if anim:
		anim.rotation = 0.0


# ===== Disparo =====
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
func _on_gun_timer_timeout() -> void:
	_update_target()
	if dead or player == null:
		return
<<<<<<< HEAD
=======
	if assault_pause_shooting and _is_assaulting:
		return
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	var to_player: Vector2 = player.global_position - global_position
	if to_player.length() > attack_range:
		return
	var bullet_instance = BULLET_ENEMY_1.instantiate()
	get_parent().add_child(bullet_instance)
	bullet_instance.global_position = global_position
	bullet_instance.rotation = to_player.angle()
	if audio_laser:
		audio_laser.stop()
		audio_laser.play()

<<<<<<< HEAD
# ============================
# DAÑO, MUERTE Y EFECTOS
# ============================

func _on_damage(amount: float) -> void:
	if bar_3:
		bar_3.value = clamp(bar_3.value - amount, bar_3.min_value, bar_3.max_value)
=======

# ===== Daño / muerte =====
func _on_damage(amount: float) -> void:
	if bar_3:
		bar_3.value = clamp(bar_3.value - amount, bar_3.min_value, bar_3.max_value)

>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	_stack_value += amount
	label.text = str(int(_stack_value))
	label.visible = true
	label.position = _label_base_pos
	label.scale = Vector2.ONE
<<<<<<< HEAD
	var sum := int(_stack_value)
	var col := Color(1, 1, 1, 1)
	if sum <= 20: col = Color(1, 1, 1, 1)
	elif sum <= 40: col = Color(1, 1, 0, 1)
	else: col = Color(1, 0, 0, 1)
	label.modulate = col
	if _tween and _tween.is_running(): _tween.kill()
=======

	var sum := int(_stack_value)
	var col := Color(1, 1, 1, 1)
	if sum <= 20:
		col = Color(1, 1, 1, 1)
	elif sum <= 40:
		col = Color(1, 1, 0, 1)
	else:
		col = Color(1, 0, 0, 1)
	label.modulate = col

	if _tween and _tween.is_running():
		_tween.kill()
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	_tween = create_tween()
	_tween.tween_property(label, "position:y", _label_base_pos.y - 18.0, 0.25)
	_tween.parallel().tween_property(label, "scale", Vector2(1.25, 1.25), 0.18)
	_tween.parallel().tween_property(label, "modulate:a", 0.0, 0.35).set_delay(0.05)
<<<<<<< HEAD
	_stack_timer.start(0.4)
	random_pitch_variations_gun()
	_process_hitstun(amount)
=======

	_stack_timer.start(0.4)
	random_pitch_variations_gun()
	_process_hitstun(amount)

>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	if not dead and bar_3 and bar_3.value <= bar_3.min_value:
		dead = true
		_end_hitstun()
		label.visible = false
<<<<<<< HEAD
		if has_node("gun_timer"): $gun_timer.stop()
		velocity = Vector2.ZERO
=======
		if has_node("gun_timer"):
			$gun_timer.stop()
		velocity = Vector2.ZERO
		_lock_rotations()
		if anim:
			anim.position = _visual_base_pos
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
		anim.play("explosion")
		$explosion_timer.start()

func _on_stack_timeout() -> void:
	_stack_value = 0.0
	label.visible = false

func _on_damage_enemy_body_entered(body: Node2D) -> void:
<<<<<<< HEAD
	if body.is_in_group("player_1_bullet") or body.is_in_group("puño_player2") :
=======
	if body.is_in_group("player_1_bullet") or body.is_in_group("puño_player2"):
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
		$AnimationPlayer.play("hit")
		emit_signal("damage", 10.0)

func _report_dead() -> void:
	if reported_dead:
		return
	reported_dead = true
<<<<<<< HEAD
	if _hitstun_timer: _hitstun_timer.stop()
	if _combo_timer: _combo_timer.stop()
	_end_hitstun()
	if _shock_timer: _shock_timer.stop()
=======
	if _hitstun_timer:
		_hitstun_timer.stop()
	if _combo_timer:
		_combo_timer.stop()
	_end_hitstun()
	if _shock_timer:
		_shock_timer.stop()
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	_is_shocked = false
	speed = _base_speed
	_drop_coin()
	emit_signal("died")
	call_deferred("queue_free")

func _on_AnimatedSprite2D_animation_finished() -> void:
	if anim.animation == "explosion":
		_report_dead()

func _on_explosion_timer_timeout() -> void:
	_report_dead()

<<<<<<< HEAD
=======

# ===== Target =====
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
func _update_target() -> void:
	var players := []
	players += get_tree().get_nodes_in_group("player")
	players += get_tree().get_nodes_in_group("player_2")
	var nearest: CharacterBody2D = null
	var nearest_dist := INF
<<<<<<< HEAD
	for p in players:
		if p and p is Node2D:
			var dist = global_position.distance_to(p.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = p
	player = nearest

=======
	var i := 0
	while i < players.size():
		var p = players[i]
		if p:
			if p is Node2D:
				var dist := global_position.distance_to((p as Node2D).global_position)
				if dist < nearest_dist:
					nearest_dist = dist
					nearest = p
		i += 1
	player = nearest


# ===== Drop =====
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
func _drop_coin():
	var coin_instance = MONEDA.instantiate()
	get_parent().add_child(coin_instance)
	coin_instance.global_position = global_position
	var sprite = coin_instance.get_node("AnimatedSprite2D")
<<<<<<< HEAD
	if sprite: sprite.play("idle")

# ============================
# ELECTROSHOCK
# ============================

func electroshock(duration: float = -1.0, factor: float = -1.0) -> void:
	if dead: return
	if duration <= 0.0: duration = shock_duration
	if factor <= 0.0: factor = shock_factor
	if not _is_shocked:
		_base_speed = speed
		_is_shocked = true
	speed = min(speed, _base_speed * factor)
	_shock_timer.start(duration)
=======
	if sprite:
		sprite.play("idle")


# ===== Electroshock =====
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
	if speed > _base_speed * factor:
		speed = _base_speed * factor
	if _shock_timer:
		_shock_timer.start(duration)
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771

func _end_electroshock() -> void:
	_is_shocked = false
	speed = _base_speed

<<<<<<< HEAD
# ============================
# HITSTUN SYSTEM
# ============================

=======

# ===== Hitstun =====
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
func _ready_hitstun_system() -> void:
	_hitstun_timer = Timer.new()
	_hitstun_timer.one_shot = true
	add_child(_hitstun_timer)
	_hitstun_timer.connect("timeout", Callable(self, "_end_hitstun"))
<<<<<<< HEAD
=======

>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	_combo_timer = Timer.new()
	_combo_timer.one_shot = true
	add_child(_combo_timer)
	_combo_timer.connect("timeout", Callable(self, "_reset_combo"))
<<<<<<< HEAD
	if anim: _original_color = anim.modulate
=======

	if anim:
		_original_color = anim.modulate
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771

func _process_hitstun(damage_amount: float) -> void:
	if damage_amount < hitstun_threshold:
		return
	if _combo_timer.time_left > 0.0:
		_combo_count += 1
	else:
		_combo_count = 1
	_combo_timer.start(combo_window)
	_enter_hitstun()
<<<<<<< HEAD
	var extended_duration = hitstun_duration + (_combo_count * 0.2)
=======
	var extended_duration := hitstun_duration + (_combo_count * 0.2)
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	_hitstun_timer.start(extended_duration)
	print("🥊 Combo x", _combo_count, " - Hitstun: ", extended_duration, "s")

func _enter_hitstun() -> void:
<<<<<<< HEAD
	if dead: return
	_in_hitstun = true
	if has_node("gun_timer") and $gun_timer:
		$gun_timer.paused = true
	if _hitstun_tween: _hitstun_tween.kill()
=======
	if dead:
		return
	_in_hitstun = true
	if has_node("gun_timer") and $gun_timer:
		$gun_timer.paused = true
	if _hitstun_tween:
		_hitstun_tween.kill()
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	_hitstun_tween = create_tween()
	_hitstun_tween.tween_property(anim, "modulate", hitstun_color, 0.1)
	speed *= 0.6
	_screen_shake_effect()

func _end_hitstun() -> void:
<<<<<<< HEAD
	if not _in_hitstun: return
	_in_hitstun = false
	if has_node("gun_timer") and $gun_timer and not dead:
		$gun_timer.paused = false
	if _hitstun_tween: _hitstun_tween.kill()
=======
	if not _in_hitstun:
		return
	_in_hitstun = false
	if has_node("gun_timer") and $gun_timer and not dead:
		$gun_timer.paused = false
	if _hitstun_tween:
		_hitstun_tween.kill()
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	_hitstun_tween = create_tween()
	_hitstun_tween.tween_property(anim, "modulate", _original_color, 0.2)
	if not _is_shocked:
		speed = _base_speed
	print("🛡️ Hitstun terminado")

func _reset_combo() -> void:
	if _combo_count > 1:
		print("💥 Combo terminado: ", _combo_count, " golpes!")
	_combo_count = 0

func _screen_shake_effect() -> void:
	var shake_tween = create_tween()
<<<<<<< HEAD
	var original_pos = anim.position
	for i in range(3):
		var offset = Vector2(randf_range(-3, 3), randf_range(-3, 3))
		shake_tween.tween_property(anim, "position", original_pos + offset, 0.05)
		shake_tween.tween_property(anim, "position", original_pos, 0.05)
=======
	var original_pos := anim.position
	var i := 0
	while i < 3:
		var offset := Vector2(randf_range(-3, 3), randf_range(-3, 3))
		shake_tween.tween_property(anim, "position", original_pos + offset, 0.05)
		shake_tween.tween_property(anim, "position", original_pos, 0.05)
		i += 1
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
