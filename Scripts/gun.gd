extends Node2D

@export var bullet_scene: PackedScene = preload("res://Scenes/bullet.tscn")
@export var ray_scene: PackedScene = preload("res://Scenes/Armas/Laser.tscn")
@export var cooldown: float = 0.5
var can_fire := true

@onready var timer: Timer = $Timer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var offset_right := Vector2(10, 0)
@export var offset_left := Vector2(-10, 0)
@export var extra_left_offset := -40

var player_flipped: bool = false
var player: Node2D
var player_sprite: AnimatedSprite2D
var visuals_node: Node2D
var base_position: Vector2

enum GunMode { RAY, PISTOL, TURRET}
var current_mode: GunMode = GunMode.RAY

@export var turret_fire_rate := 0.15
@export var turret_angle_limit := deg_to_rad(50)

var current_ray: Node = null
@export var ray_dmg := 30
@export var ray_duration_max := 4.0
@export var ray_dmg_reduction := 5.0

var base_rotation: float = 0.0
var aim_angle: float = 0.0

func _ready() -> void:
	if animated_sprite: animated_sprite.offset = Vector2(-16, 0)
	timer.one_shot = true
	# El wait_time se establece dinámicamente
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

	player_flipped = (player_sprite != null and player_sprite.flip_h)

	var offset = offset_left if player_flipped else offset_right
	if player_flipped:
		offset.x += extra_left_offset

	position = base_position + offset

	if animated_sprite:
		if current_mode == GunMode.TURRET:
			animated_sprite.flip_h = false
			animated_sprite.flip_v = player_flipped
		else:
			animated_sprite.flip_h = player_flipped
			animated_sprite.flip_v = false

	if ("dead" in player and player.dead) or ("allow_input" in player and not player.allow_input and not ("is_using_ulti" in player and player.is_using_ulti)):
		return

	if current_mode == GunMode.TURRET:
		_update_turret_aim(player_flipped)
	else:
		rotation = base_rotation
		aim_angle = base_rotation

	# NUEVA LÓGICA DE MANEJO DE INPUT
	match current_mode:
		GunMode.RAY:
			if Input.is_action_just_pressed("attack"):
				_start_ray()
			elif Input.is_action_just_released("attack"):
				_stop_ray()
		GunMode.PISTOL:
			if Input.is_action_just_pressed("fired") and can_fire:
				_fire(player_flipped)
		GunMode.TURRET:
			if Input.is_action_pressed("fired") and can_fire:
				_fire_at_mouse(player_flipped)


# ========================
# TURRET aiming (sin cambios)
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

# ===================================
# RAYO
# ====================================

func _start_ray() -> void:
	# Si ya hay un rayo, no hagas nada
	if current_ray != null:
		return

	#if animated_sprite:
		#animated_sprite.play("laser_fire")

	var ray_instance = ray_scene.instantiate()
	if not ray_instance:
		push_error("La escena del rayo no está bien asignada.")
		return

	get_tree().current_scene.add_child(ray_instance)
	ray_instance.global_position = global_position
	
	var dir_ray = (Vector2.LEFT if player_flipped else Vector2.RIGHT).rotated(aim_angle)
	ray_instance.direction = dir_ray
	ray_instance.rotation = dir_ray.angle()

	# Pasar parámetros al rayo
	if ray_instance.has_method("start"):
		ray_instance.start(ray_duration_max, ray_dmg, ray_dmg_reduction)
	
	# Guardar referencia y conectar la señal
	current_ray = ray_instance
	current_ray.connect("tree_exited", Callable(self, "_on_ray_removed"))

func _stop_ray() -> void:
	if current_ray != null:
		current_ray.queue_free()
		# El timer de cooldown se activa cuando el rayo es eliminado del árbol en _on_ray_removed

func _on_ray_removed() -> void:
	current_ray = null
	# Aquí iniciamos el cooldown.
	can_fire = false
	timer.wait_time = cooldown
	timer.start()

# Funciones de disparo y efectos (sin cambios mayores)
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
	can_fire = true
	match current_mode:
		GunMode.RAY:
			pass
		GunMode.PISTOL:
			timer.stop()
			if animated_sprite:
				animated_sprite.play("idle")
				animated_sprite.flip_h = (player_sprite != null and player_sprite.flip_h)
				animated_sprite.flip_v = false
			rotation = base_rotation
			aim_angle = base_rotation

			var offset = offset_left if (player_sprite and player_sprite.flip_h) else offset_right
			if player_sprite and player_sprite.flip_h:
				offset.x += extra_left_offset
			position = base_position + offset
		GunMode.TURRET:
			if animated_sprite:
				animated_sprite.play("metralleta")
				animated_sprite.flip_h = false
				animated_sprite.flip_v = (player_sprite != null and player_sprite.flip_h)
