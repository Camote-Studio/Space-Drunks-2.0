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
var grab_range := 100.0          # distancia a la que inicia el agarre
var grab_duration := 3.0         # tiempo pegado
var grab_dps := 8.0              # daño por segundo durante el agarre
var grab_tick := 0.25            # cada cuánto aplica daño
var grab_cooldown := 1.2         # enfriamiento antes de volver a agarrar
var attach_offset := 8.0         # qué tan “encimado” se pega al jugador

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

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	add_to_group("enemy_5")

	# Vida llena al iniciar
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

	# Timers
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

func _physics_process(delta: float) -> void:
	_update_target()
	if dead or player == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_player := player.global_position - global_position
	var dist := to_player.length()
	var dir := to_player.normalized()

	match state:
		State.CHASE:
			# SIEMPRE avanzar hacia el jugador (sin “bailes” ni alejarse)
			var target_vel := dir * speed
			velocity = velocity.move_toward(target_vel, accel * delta)
			# Iniciar agarre cuando esté cerca y sin cooldown
			if dist <= grab_range and _grab_cd_timer.time_left <= 0.0:
				_start_grab()
		State.GRAB:
			# Mantenerse pegado al jugador (reposicionar constantemente)
			var anchor := player.global_position - dir * attach_offset
			global_position = global_position.move_toward(anchor, accel * delta * 0.02)
			velocity = Vector2.ZERO

	# Cara (flip)
	if abs(dir.x) > 0.1:
		face_sign = sign(dir.x)
	sprite_2d.flip_h = face_sign < 0.0

	move_and_slide()

func _start_grab() -> void:
	if state != State.CHASE:
		return
	state = State.GRAB
	$attack.play()
	_dot_timer.start()
	_grab_timer.start(grab_duration)

func _on_dot_tick() -> void:
	if state == State.GRAB and player:
		# Daño periódico al jugador
		player.emit_signal("damage", grab_dps * grab_tick,"veneno")
	else:
		_dot_timer.stop()

func _on_grab_timer_timeout() -> void:
	# Termina agarre -> vuelve a perseguir (sin retroceder)
	_dot_timer.stop()
	state = State.CHASE
	_grab_cd_timer.start(grab_cooldown)

func _on_grab_cd_timeout() -> void:
	# cooldown terminado; sin acción extra
	pass

# ===== Colisiones de área =====
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("player_2"):
		# no guardamos ref aquí; usamos 'player' ya encontrado
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

# ===== Daño/vida UI =====
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

	if not dead and bar_7 and bar_7.value <= bar_7.min_value:
		_die()

func _on_stack_timeout() -> void:
	_stack_value = 0.0
	label.visible = false

# ===== Muerte/Explosión =====
func _die() -> void:
	dead = true
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
		if not reported_dead:
			_drop_coin()
			reported_dead = true
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
