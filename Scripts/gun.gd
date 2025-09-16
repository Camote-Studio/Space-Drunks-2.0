extends Node2D
# Gun.gd - arma con comportamiento PISTOL/TURRET con flip_v al mirar izquierda

@export var bullet_scene: PackedScene = preload("res://Scenes/bullet.tscn")
@export var cooldown: float = 0.5
var can_fire := true

@onready var timer: Timer = $Timer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Offset del arma respecto al jugador
@export var offset_right := Vector2(10, 0)
@export var offset_left := Vector2(-10, 0)
@export var extra_left_offset := -40   # ✅ extra en X cuando mira a la izquierda

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

func _ready() -> void:
	if animated_sprite:animated_sprite.offset = Vector2(-16, 0)
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

func _process(delta: float) -> void:
	if not player:
		return

	var player_flipped := (player_sprite != null and player_sprite.flip_h)

	# Offset depende de la dirección del jugador
	var offset = offset_left if player_flipped else offset_right
	if player_flipped:
		offset.x += extra_left_offset   # ✅ mover 100px más a la izquierda

	position = base_position + offset


	# 🚫 En idle (PISTOL) no debe tener flip_v, solo en TURRET
	if animated_sprite:
		if current_mode == GunMode.TURRET:
			animated_sprite.flip_h = false
			animated_sprite.flip_v = player_flipped
		else: # PISTOL
			animated_sprite.flip_h = player_flipped   # ✅ sigue al jugador
			animated_sprite.flip_v = false           # 🚫 nunca vertical

	# Evitar input si no puede
	if ("dead" in player and player.dead) or ("allow_input" in player and not player.allow_input and not ("is_using_ulti" in player and player.is_using_ulti)):
		return

	# Modo de disparo
	if current_mode == GunMode.TURRET:
		_update_turret_aim(player_flipped)
	else:
		rotation = base_rotation
		aim_angle = base_rotation

	match current_mode:
		GunMode.PISTOL:
			if Input.is_action_just_pressed("fired") and can_fire:
				_fire(player_flipped)
		GunMode.TURRET:
			if Input.is_action_pressed("fired") and can_fire:
				_fire_at_mouse(player_flipped)

# ========================
#  TURRET aiming
# ========================
func _update_turret_aim(player_flipped: bool) -> void:
	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - global_position).normalized()
	if dir.length() < 0.001:
		dir = Vector2.RIGHT

	var forward = Vector2.RIGHT if not player_flipped else Vector2.LEFT
	var forward_angle = forward.angle()
	var target_angle = dir.angle()

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

# ========================
#  Disparo
# ========================
func _fire(is_flipped: bool) -> void:
	if animated_sprite:
		animated_sprite.play("idle")

	var bullet_instance = bullet_scene.instantiate()
	if bullet_instance == null:
		push_error("❌ bullet_scene no está bien asignado.")
		return

	get_tree().current_scene.add_child(bullet_instance)
	bullet_instance.global_position = global_position

	var dir = (Vector2.LEFT if is_flipped else Vector2.RIGHT).rotated(aim_angle)
	bullet_instance.direction = dir
	bullet_instance.rotation = dir.angle()

	_apply_bullet_effects(bullet_instance)

	can_fire = false
	timer.wait_time = cooldown
	timer.start()

func _fire_at_mouse(flipped: bool) -> void:
	if animated_sprite:
		animated_sprite.play("metralleta")

	var bullet_dir = Vector2.RIGHT.rotated(aim_angle)
	var bullet_instance = bullet_scene.instantiate()
	if bullet_instance == null:
		push_error("❌ bullet_scene no está bien asignado.")
		return

	get_tree().current_scene.add_child(bullet_instance)
	bullet_instance.global_position = global_position
	bullet_instance.direction = bullet_dir
	bullet_instance.rotation = bullet_dir.angle()

	_apply_bullet_effects(bullet_instance)

	can_fire = false
	timer.wait_time = turret_fire_rate
	timer.start()

func _apply_bullet_effects(bullet_instance: Node2D) -> void:
	if player:
		if player.has_method("apply_power_to_bullet"):
			player.apply_power_to_bullet(bullet_instance)
		if player.has_method("gain_ability_from_shot"):
			player.gain_ability_from_shot()

func _on_timer_timeout() -> void:
	can_fire = true

func set_mode(mode: GunMode) -> void:
	current_mode = mode
	match current_mode:
		GunMode.PISTOL:
			timer.stop()
			if animated_sprite:
				animated_sprite.play("idle")
				animated_sprite.flip_h = (player_sprite != null and player_sprite.flip_h) # ✅ sigue dirección
				animated_sprite.flip_v = false
			rotation = base_rotation
			aim_angle = base_rotation

			var offset = offset_left if (player_sprite and player_sprite.flip_h) else offset_right
			if player_sprite and player_sprite.flip_h:
				offset.x += extra_left_offset   # ✅ aplicar extra también al cambiar modo
			position = base_position + offset

			can_fire = true

		GunMode.TURRET:
			if animated_sprite:
				animated_sprite.play("metralleta")
				animated_sprite.flip_h = false
				animated_sprite.flip_v = (player_sprite != null and player_sprite.flip_h)
			can_fire = true
