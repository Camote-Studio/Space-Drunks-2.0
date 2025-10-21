extends CharacterBody2D

signal damage(value: float)
signal died

var speed := 150.0
var player: CharacterBody2D = null
var dead := false
var reported_dead := false
var target_in_range: CharacterBody2D = null
@onready var audio_ataque: AudioStreamPlayer2D = $hit
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

# === EMBESTIDA (Toro) ===
@export var charge_enabled: bool = true
@export var charge_trigger_min: float = 120.0
@export var charge_trigger_max: float = 360.0
@export var charge_windup: float = 0.30
@export var charge_speed: float = 520.0
@export var charge_max_time: float = 0.9
@export var charge_cooldown: float = 2.5
@export var charge_damage: float = 22.0
@export var charge_hit_push: float = 120.0  # (se mantiene por si tu Player no soporta empuje continuo)
@export var charge_wall_stop: bool = true
@export var charge_pause_melee: bool = true

@export var charge_overrides_melee: bool = true
@export var charge_intent_margin: float = 30.0

# >>> NUEVO: Empuje continuo (SHOVE) tras impactar <<<
@export var charge_shove_time: float = 0.35       # cuánto dura el “empujón”
@export var charge_shove_speed: float = 260.0     # unidades/seg que empuja al player
@export var charge_shove_follow_speed_factor: float = 0.7 # el toro sigue detrás más lento
@export var charge_first_hit_damage_only: bool = true     # daño solo 1 vez por embestida

const CHARGE_NONE := 0
const CHARGE_WINDUP := 1
const CHARGE_RUN := 2
const CHARGE_RECOVERY := 3
const CHARGE_SHOVE := 4  # <<< nuevo estado

var _charge_state := CHARGE_NONE
var _is_charging := false
var _charge_dir := Vector2.ZERO
var _charge_elapsed := 0.0
var _charge_hit_done := false
var _charge_cooldown_timer: Timer
var _charge_state_timer: Timer
var _charge_timer: Timer

# SHOVE runtime
var _shove_body: Node2D = null
var _shove_time_left: float = 0.0

const MONEDA = preload("res://Scenes/Items/items_interectables/moneda.tscn")

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
	
	_base_speed = speed
	_shock_timer = Timer.new()
	_shock_timer.one_shot = true
	add_child(_shock_timer)
	if not _shock_timer.is_connected("timeout", Callable(self, "_end_electroshock")):
		_shock_timer.connect("timeout", Callable(self, "_end_electroshock"))

	_ready_hitstun_system()

	# Timers embestida
	_charge_cooldown_timer = Timer.new()
	_charge_cooldown_timer.one_shot = true
	add_child(_charge_cooldown_timer)

	_charge_state_timer = Timer.new()
	_charge_state_timer.one_shot = true
	add_child(_charge_state_timer)
	_charge_state_timer.connect("timeout", Callable(self, "_on_charge_state_timeout"))

	_charge_timer = Timer.new()
	_charge_timer.one_shot = true
	add_child(_charge_timer)
	_charge_timer.connect("timeout", Callable(self, "_on_charge_timeout"))

func _ready_hitstun_system() -> void:
	_hitstun_timer = Timer.new()
	_hitstun_timer.one_shot = true
	add_child(_hitstun_timer)
	_hitstun_timer.connect("timeout", Callable(self, "_end_hitstun"))
	
	_combo_timer = Timer.new()
	_combo_timer.one_shot = true
	add_child(_combo_timer)
	_combo_timer.connect("timeout", Callable(self, "_reset_combo"))
	
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
	var dir := Vector2.ZERO
	if dist > 0.0:
		dir = to_player / dist

	# ======== EMBESTIDA: prioridad de estados ========
	if _is_charging:
		_charge_elapsed += delta

		if _charge_state == CHARGE_WINDUP:
			velocity = velocity.move_toward(Vector2.ZERO, 0.35)
			_play_anim_if_exists("cargar")
			_face_dir(_charge_dir.x)
			move_and_slide()
			return

		if _charge_state == CHARGE_RUN:
			var desired := _charge_dir * charge_speed
			velocity = velocity.move_toward(desired, 0.45)
			_face_dir(_charge_dir.x)
			move_and_slide()

			_try_charge_hit()

			if charge_wall_stop:
				if get_slide_collision_count() > 0:
					_start_charge_recovery()
					return

			if _charge_elapsed >= charge_max_time:
				_start_charge_recovery()
				return
			return

		if _charge_state == CHARGE_SHOVE:
			# Empuje continuo al player mientras seguimos detrás
			var desired_shove := _charge_dir * (charge_speed * charge_shove_follow_speed_factor)
			velocity = velocity.move_toward(desired_shove, 0.5)
			_face_dir(_charge_dir.x)
			move_and_slide()

			if is_instance_valid(_shove_body):
				if _shove_body.has_method("push_temp"):
					_shove_body.call("push_temp", _charge_dir * charge_shove_speed * delta)
			_shove_time_left -= delta

			if charge_wall_stop:
				if get_slide_collision_count() > 0:
					_start_charge_recovery()
					return

			if _shove_time_left <= 0.0 or not is_instance_valid(_shove_body):
				_start_charge_recovery()
			return

		if _charge_state == CHARGE_RECOVERY:
			velocity = velocity.move_toward(Vector2.ZERO, 0.30)
			_play_anim_if_exists("idle")
			move_and_slide()
			return

	# ======== MOVIMIENTO NORMAL ========
	var movement_multiplier := 1.0
	if _in_hitstun:
		movement_multiplier = 0.15

	var target_vel := Vector2.ZERO
	walk_phase += delta
	var offset := Vector2.ZERO
	if dist > max_range * 0.9:
		var phase := walk_phase * TAU
		offset = Vector2(sin(phase * walk_freq + walk_seed) * side_amp,
						 sin(phase * up_freq + walk_seed * 0.73) * up_amp)

	if _attack_lock and not _in_hitstun:
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

	if abs(dir.x) > 0.1:
		_face_dir(dir.x)

	move_and_slide()

	# Prioridad: si puede embestir, lo hace (cancelando punch si es necesario)
	if _can_charge(dist) and charge_overrides_melee and not _is_charging:
		if _attack_lock:
			_cancel_current_attack()
		_start_charge(dir)

	# Punch solo si no hay embestida prioritaria activa o posible
	if (dist <= attack_range 
		and target_in_range 
		and punch_timer.time_left <= 0.0 
		and not dead 
		and not _attack_lock 
		and not _attack_anim_lock 
		and not _in_hitstun 
		and not _is_charging 
		and not (_can_charge(dist) and charge_overrides_melee)):
		_do_punch(dir)

	_try_start_charge(dist, dir)

func _can_charge(dist: float) -> bool:
	if not charge_enabled:
		return false
	if _in_hitstun:
		return false
	if _is_charging:
		return false
	if dist < (charge_trigger_min - charge_intent_margin):
		return false
	if dist > (charge_trigger_max + charge_intent_margin):
		return false
	if _charge_cooldown_timer and _charge_cooldown_timer.time_left > 0.0:
		return false
	return true

func _face_dir(dx: float) -> void:
	if dx == 0.0:
		return
	face_sign = 1.0
	if dx < 0.0:
		face_sign = -1.0
	sprite_2d.flip_h = face_sign > 0.0

func _play_anim_if_exists(name: String) -> void:
	if sprite_2d and sprite_2d.sprite_frames and sprite_2d.sprite_frames.has_animation(name):
		if sprite_2d.animation != name:
			sprite_2d.play(name)

# ========= EMBESTIDA: control =========
func _try_start_charge(dist: float, dir: Vector2) -> void:
	if not _can_charge(dist):
		return
	if not _is_charging:
		_start_charge(dir)

func _start_charge(dir: Vector2) -> void:
	if dir.length() < 0.001:
		return
	_is_charging = true
	_charge_state = CHARGE_WINDUP
	_charge_dir = dir.normalized()
	_charge_elapsed = 0.0
	_charge_hit_done = false
	_shove_body = null
	_shove_time_left = 0.0
	_attack_lock = true

	_play_anim_if_exists("cargar")
	_face_dir(_charge_dir.x)

	if _charge_state_timer:
		_charge_state_timer.start(charge_windup)

func _on_charge_state_timeout() -> void:
	if _charge_state == CHARGE_WINDUP:
		_charge_state = CHARGE_RUN
		_charge_elapsed = 0.0
		if _charge_timer:
			_charge_timer.start(charge_max_time)
		_play_anim_if_exists("ataque")
	elif _charge_state == CHARGE_RECOVERY:
		_end_charge()

func _on_charge_timeout() -> void:
	if _charge_state == CHARGE_RUN:
		_start_charge_recovery()

func _start_charge_shove(body: Node) -> void:
	# Daño al entrar a SHOVE (solo una vez si así lo quieres)
	if charge_first_hit_damage_only:
		if not _charge_hit_done:
			if body.has_method("emit_signal"):
				body.emit_signal("damage", charge_damage)
			_charge_hit_done = true
	else:
		# si quisieras daño por tick, podrías hacerlo aquí acumulado
		if body.has_method("emit_signal"):
			body.emit_signal("damage", charge_damage)

	if audio_ataque:
		audio_ataque.stop()
		audio_ataque.play()

	_shove_body = body as Node2D
	_shove_time_left = charge_shove_time

	# pasamos a estado SHOVE y cancelamos el timer de RUN
	_charge_state = CHARGE_SHOVE
	_charge_elapsed = 0.0
	if _charge_timer and _charge_timer.time_left > 0.0:
		_charge_timer.stop()

func _on_charge_contact(body: Node) -> void:
	# Helper centralizado por claridad
	if body == null:
		return
	if not _is_charging:
		return
	if _charge_state != CHARGE_RUN and _charge_state != CHARGE_SHOVE:
		return
	# Si ya estaba shoving, no reiniciar
	if _charge_state == CHARGE_SHOVE:
		return
	_start_charge_shove(body)

func _on_charge_bump_wall() -> void:
	if charge_wall_stop:
		_start_charge_recovery()

func _start_charge_recovery() -> void:
	_charge_state = CHARGE_RECOVERY
	_charge_elapsed = 0.0
	_shove_body = null
	_shove_time_left = 0.0
	if _charge_state_timer:
		_charge_state_timer.start(0.35)

func _end_charge() -> void:
	_is_charging = false
	_charge_state = CHARGE_NONE
	_charge_dir = Vector2.ZERO
	_charge_elapsed = 0.0
	_charge_hit_done = false
	_shove_body = null
	_shove_time_left = 0.0
	velocity = Vector2.ZERO
	_attack_lock = false
	_play_anim_if_exists("idle")
	if _charge_cooldown_timer:
		_charge_cooldown_timer.start(charge_cooldown)

func _try_charge_hit() -> void:
	if _charge_state != CHARGE_RUN:
		return
	# revisar cuerpos superpuestos para iniciar SHOVE
	var bodies := area.get_overlapping_bodies()
	var i := 0
	while i < bodies.size():
		var b = bodies[i]
		if b and (b.is_in_group("player") or b.is_in_group("player_2")):
			_on_charge_contact(b)
			return
		i += 1

# ========= MELEE normal =========
func _do_punch(dir: Vector2) -> void:
	if _in_hitstun:
		return
		
	if target_in_range:
		var direction_to_player = (target_in_range.global_position - global_position).normalized()
		if direction_to_player.x != 0.0:
			_face_dir(direction_to_player.x)
		
		if target_in_range.has_method("emit_signal"):
			target_in_range.emit_signal("damage", punch_damage)
	
	if audio_ataque:
		audio_ataque.stop()
		audio_ataque.play()
	
	if sprite_2d:
		sprite_2d.play("ataque")
		_attack_anim_lock = true

	_attack_lock = true
	if _tween and _tween.is_running():
		_tween.kill()
	
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
		_play_anim_if_exists("idle")
	elif sprite_2d.animation == "explosion":
		if explosion_timer and explosion_timer.time_left > 0.0:
			explosion_timer.stop()
		if _is_shocked:
			_end_electroshock()
		if not reported_dead:
			var killer_id = _determine_killer()
			if killer_id != "":
				# KillTracker.register_kill(killer_id, "enemy_3")
				pass
			reported_dead = true
			_drop_coin()
			emit_signal("died")
		queue_free()

func _determine_killer() -> String:
	var players = []
	players += get_tree().get_nodes_in_group("player")
	players += get_tree().get_nodes_in_group("player_2")
	
	var closest_player = null
	var closest_dist = INF
	
	for p in players:
		if p and p is Node2D:
			var d = global_position.distance_to(p.global_position)
			if d < closest_dist and d < 200.0:
				closest_dist = d
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

	# Si está embistiendo y toca al player: inicia SHOVE (empuje continuo)
	if _is_charging and ( _charge_state == CHARGE_RUN or _charge_state == CHARGE_SHOVE ):
		if body.is_in_group("player") or body.is_in_group("player_2"):
			_on_charge_contact(body)
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

	_process_hitstun(amount)

	if not dead and bar_5 and bar_5.value <= bar_5.min_value:
		_die()

func _process_hitstun(damage_amount: float) -> void:
	if damage_amount < hitstun_threshold:
		return
	
	if _combo_timer.time_left > 0.0:
		_combo_count += 1
	else:
		_combo_count = 1
	
	_combo_timer.start(combo_window)
	_enter_hitstun()
	var extended_duration = hitstun_duration + (_combo_count * 0.15)
	_hitstun_timer.start(extended_duration)

func _enter_hitstun() -> void:
	if dead:
		return
		
	_in_hitstun = true
	
	if punch_timer:
		punch_timer.paused = true
	
	if _is_charging:
		_end_charge()
	
	if _attack_lock:
		_cancel_current_attack()
	
	if _hitstun_tween:
		_hitstun_tween.kill()
	_hitstun_tween = create_tween()
	_hitstun_tween.tween_property(sprite_2d, "modulate", hitstun_color, 0.08)
	
	speed *= 0.25
	_screen_shake_effect_melee()
	
	if sprite_2d and sprite_2d.sprite_frames.has_animation("hitstun"):
		sprite_2d.play("hitstun")

func _end_hitstun() -> void:
	if not _in_hitstun:
		return
		
	_in_hitstun = false
	
	if punch_timer and not dead:
		punch_timer.paused = false
	
	if _hitstun_tween:
		_hitstun_tween.kill()
	_hitstun_tween = create_tween()
	_hitstun_tween.tween_property(sprite_2d, "modulate", _original_color, 0.15)
	
	if not _is_shocked:
		speed = _base_speed
	
	if not dead and sprite_2d and sprite_2d.sprite_frames.has_animation("idle"):
		sprite_2d.play("idle")

func _cancel_current_attack() -> void:
	_attack_lock = false
	_attack_anim_lock = false
	if _tween and _tween.is_running():
		_tween.kill()
	if punch_timer:
		punch_timer.stop()

func _reset_combo() -> void:
	if _combo_count > 1:
		print("Combo Melee terminado: ", _combo_count, " golpes!")
	_combo_count = 0

func _screen_shake_effect_melee() -> void:
	var shake_tween = create_tween()
	var original_pos = sprite_2d.position
	var i := 0
	while i < 5:
		var offset := Vector2(randf_range(-6, 6), randf_range(-6, 6))
		shake_tween.tween_property(sprite_2d, "position", original_pos + offset, 0.03)
		shake_tween.tween_property(sprite_2d, "position", original_pos, 0.03)
		i += 1

func _on_stack_timeout() -> void:
	_stack_value = 0.0
	label.visible = false

func _die() -> void:
	dead = true
	
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
			var d := global_position.distance_to(p.global_position)
			if d < nearest_dist:
				nearest_dist = d
				nearest = p
	player = nearest

func _drop_coin() -> void:
	var coin_instance := MONEDA.instantiate()
	get_parent().add_child(coin_instance)
	coin_instance.global_position = global_position
	var sprite := coin_instance.get_node("AnimatedSprite2D")
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
