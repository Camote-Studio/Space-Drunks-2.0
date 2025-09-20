extends Node2D
# Gun.gd - arma con comportamiento PISTOL / TURRET

## --- EXPORTACIONES ---
@export var bullet_scene: PackedScene = preload("res://Scenes/bullet.tscn")
@export var cooldown: float = 0.5

# Offset del arma respecto al jugador
@export var offset_right := Vector2(10, 0)
@export var offset_left := Vector2(-10, 0)
@export var extra_left_offset := -40  # ✅ extra en X cuando mira a la izquierda

# Efectos opcionales
@export var muzzle_flash: PackedScene
@export var fire_sound: AudioStream

## --- VARIABLES INTERNAS ---
var can_fire := true
@onready var timer: Timer = $Timer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Referencias
var player: Node2D
var player_sprite: AnimatedSprite2D
var visuals_node: Node2D
var base_position: Vector2

# Modo de disparo
enum GunMode { PISTOL, TURRET }
var current_mode: GunMode = GunMode.PISTOL

# Ráfaga de metralleta (ulti)
@export var turret_fire_rate := 0.15
@export var turret_angle_limit := deg_to_rad(50) # ±50° desde el frente del arma

# Guarda la rotación base para restaurar al terminar la ulti
var base_rotation: float = 0.0
# Ángulo actual de apuntado (global)
var aim_angle: float = 0.0


## ========================
## READY
## ========================
func _ready() -> void:
	timer.one_shot = true
	timer.wait_time = cooldown
	if not timer.is_connected("timeout", Callable(self, "_on_timer_timeout")):
		timer.connect("timeout", Callable(self, "_on_timer_timeout"))

	player = get_parent()
	if player:
		if player.has_node("Visuals/AnimatedSprite2D"):
			visuals_node = player.get_node("Visuals")
			player_sprite = visuals_node.get_node("AnimatedSprite2D")
		elif player.has_node("AnimatedSprite2D"):
			player_sprite = player.get_node("AnimatedSprite2D")

	base_position = position
	base_rotation = rotation
	aim_angle = base_rotation

	if animated_sprite:
		animated_sprite.play("idle")
		animated_sprite.flip_h = false
		animated_sprite.flip_v = false


## ========================
## PROCESS
## ========================
func _process(delta: float) -> void:
	if not player:
		return

	var player_flipped := (player_sprite != null and player_sprite.flip_h)

	_update_offset(player_flipped)

	# Idle → solo flip horizontal, no vertical
	if animated_sprite:
		if current_mode == GunMode.TURRET:
			animated_sprite.flip_h = false
			animated_sprite.flip_v = player_flipped
		else:
			animated_sprite.flip_h = player_flipped
			animated_sprite.flip_v = false

	# Evitar input si está muerto o bloqueado
# DESPUÉS (Añade la comprobación de 'floating'):
	if ("dead" in player and player.dead) or ("floating" in player and player.floating) or ("allow_input" in player and not player.allow_input and not ("is_using_ulti" in player and player.is_using_ulti)):
		return

	# Modo de disparo
	if current_mode == GunMode.TURRET:
		_update_turret_aim(player_flipped)

		if Input.is_action_pressed("fired") and can_fire:
			_fire_at_mouse(player_flipped)
		elif not Input.is_action_pressed("fired"):
			# 🔊 Detener metralleta cuando se deja de disparar
			if player and player.has_node("audio_disparo_metra"):
				var metra = player.get_node("audio_disparo_metra") as AudioStreamPlayer2D
				if metra.playing:
					metra.stop()
	else:
		rotation = base_rotation
		aim_angle = base_rotation

		if Input.is_action_just_pressed("fired") and can_fire:
			_fire(player_flipped)

## ========================
## OFFSET
## ========================
func _update_offset(player_flipped: bool) -> void:
	var offset = offset_left if player_flipped else offset_right
	if player_flipped:
		offset.x += extra_left_offset
	position = base_position + offset


## ========================
## TURRET aiming
## ========================
func _update_turret_aim(player_flipped: bool) -> void:

	var aim_dir := Vector2.ZERO
	
	# 1. Intentamos obtener la dirección del joystick
	var joy_vector := Input.get_vector("aim_left_p1", "aim_right_p1", "aim_up_p1", "aim_down_p1")
	
	# 2. Si el joystick se está moviendo, usamos su dirección
	if joy_vector.length() > 0.5: # Usamos 0.5 como "deadzone" para evitar drift
		aim_dir = joy_vector.normalized()
	else: # 3. Si no, usamos la posición del ratón como antes
		aim_dir = (get_global_mouse_position() - global_position).normalized()

	# El resto de la función es igual, pero usa aim_dir
	if aim_dir.length() < 0.001:
		aim_dir = Vector2.RIGHT

	var forward = Vector2.RIGHT if not player_flipped else Vector2.LEFT
	var forward_angle = forward.angle()
	var target_angle = aim_dir.angle()

	var relative = wrapf(target_angle - forward_angle, -PI, PI)
	var display_rel_angle: float = clamp(relative, -turret_angle_limit, turret_angle_limit)
	var final_angle = forward_angle + display_rel_angle

	rotation = final_angle
	aim_angle = final_angle

	if animated_sprite:
		if animated_sprite.animation != "metralleta":
			animated_sprite.play("metralleta")
		animated_sprite.flip_h = false
		animated_sprite.flip_v = player_flipped


## ========================
## Disparo
## ========================
func _fire(is_flipped: bool) -> void:
	if not bullet_scene:
		push_error("❌ bullet_scene no está asignado.")
		return

	if animated_sprite:
		animated_sprite.play("idle")

	var bullet_instance = bullet_scene.instantiate()
	bullet_instance.owner_node = player 
	get_tree().current_scene.add_child(bullet_instance)

	bullet_instance.global_position = global_position
	var dir = (Vector2.LEFT if is_flipped else Vector2.RIGHT).rotated(aim_angle)
	bullet_instance.direction = dir
	bullet_instance.rotation = dir.angle()

	_apply_bullet_effects(bullet_instance)
	_do_recoil()
	_play_effects()

	can_fire = false
	timer.wait_time = cooldown
	timer.start()

func _fire_at_mouse(flipped: bool) -> void:
	if not bullet_scene:
		push_error("❌ bullet_scene no está asignado.")
		return

	if animated_sprite:
		animated_sprite.play("metralleta")

	var bullet_dir = Vector2.RIGHT.rotated(aim_angle)
	var bullet_instance = bullet_scene.instantiate()
	
	bullet_instance.owner_node = player
	
	get_tree().current_scene.add_child(bullet_instance)

	bullet_instance.global_position = global_position
	bullet_instance.direction = bullet_dir
	bullet_instance.rotation = bullet_dir.angle()

	_apply_bullet_effects(bullet_instance)
	_do_recoil()

	# 🔊 Inicia audio de metralleta si no está sonando
	if player and player.has_node("audio_disparo_metra"):
		var metra = player.get_node("audio_disparo_metra") as AudioStreamPlayer2D
		if not metra.playing:
			metra.play()

	can_fire = false
	timer.wait_time = turret_fire_rate
	timer.start()


## ========================
## Extras
## ========================
func _apply_bullet_effects(bullet_instance: Node2D) -> void:
	if player:
		if player.has_method("apply_power_to_bullet"):
			player.apply_power_to_bullet(bullet_instance)
		
		# BORRA O COMENTA LA SIGUIENTE LÍNEA
		if player.has_method("gain_ability_from_shot"):
			player.gain_ability_from_shot()

# Retroceso visual
func _do_recoil() -> void:
	var recoil_strength := 4.0
	position -= Vector2.RIGHT.rotated(aim_angle) * recoil_strength

# Flash + sonido
func _play_effects() -> void:
	if muzzle_flash:
		var flash = muzzle_flash.instantiate()
		add_child(flash)
		flash.global_position = global_position

	if fire_sound:
		var audio = AudioStreamPlayer2D.new()
		add_child(audio)
		audio.stream = fire_sound
		audio.play()


## ========================
## TIMER
## ========================
func _on_timer_timeout() -> void:
	can_fire = true


## ========================
## CAMBIO DE MODO
## ========================
func set_mode(mode: GunMode) -> void:
	current_mode = mode

	match current_mode:
		GunMode.PISTOL:
			timer.stop()
			if animated_sprite:
				animated_sprite.play("idle")
				animated_sprite.flip_h = (player_sprite != null and player_sprite.flip_h)
				animated_sprite.flip_v = false

			rotation = base_rotation
			aim_angle = base_rotation
			_update_offset(player_sprite and player_sprite.flip_h)
			can_fire = true

		GunMode.TURRET:
			if animated_sprite:
				animated_sprite.play("metralleta")
				animated_sprite.flip_h = false
				animated_sprite.flip_v = (player_sprite != null and player_sprite.flip_h)
			can_fire = true
