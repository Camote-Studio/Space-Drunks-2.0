# gun.gd: Versión corregida y refactorizada
extends Node2D

## --- EXPORTACIONES Y PROPIEDADES ---
@export var bullet_scene: PackedScene
@export var ray_scene: PackedScene

# Para hacerlo más robusto, asigna el AnimatedSprite2D del jugador aquí desde el editor.
@export var player_sprite_path: NodePath

@export_group("Stats Base")
@export var cooldown: float = 0.5

@export_group("Posicionamiento")
@export var offset_right := Vector2(10, 0)
@export var offset_left := Vector2(-10, 0)
@export var extra_left_offset := -40

@export_group("Modo Torreta")
@export var turret_fire_rate := 0.15
@export var turret_angle_limit := deg_to_rad(50)

@export_group("Modo Rayo")
@export var ray_dmg := 30.0
@export var ray_duration_max := 4.0
@export var ray_dmg_reduction := 5.0


## --- REFERENCIAS A NODOS ---
@onready var timer: Timer = $Timer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player_sprite: AnimatedSprite2D = get_node_or_null(player_sprite_path)
@onready var muzzle: Marker2D = $Muzzle

## --- VARIABLES DE ESTADO ---
enum GunMode { RAY, PISTOL, TURRET }
var current_mode: GunMode = GunMode.RAY

var can_fire := true
var player: Node2D
var current_ray: Node = null
var base_position: Vector2
var base_rotation: float
var aim_angle: float = 0.0


func _ready() -> void:
	player = get_parent()

	# Comprobación de seguridad para el sprite del jugador.
	if not player_sprite:
		push_warning("⚠️ El sprite del jugador no está asignado en el gun.gd. El arma podría no funcionar correctamente.")

	timer.one_shot = true
	timer.connect("timeout", _on_timer_timeout)

	base_position = position
	base_rotation = rotation
	aim_angle = base_rotation

	if animated_sprite:
		animated_sprite.play("idle")


func _process(delta: float) -> void:
	if not player or not player_sprite:
		return

	# Comprueba si el jugador puede actuar. Es más seguro usar métodos que acceder a variables directamente.
	# NOTA: Debes crear un método `is_unable_to_act()` en tu script de jugador.
	if player.has_method("is_unable_to_act") and player.is_unable_to_act():
		if current_ray: _stop_ray() # Detiene el rayo si el jugador muere o es deshabilitado.
		return

	var is_player_flipped := player_sprite.flip_h
	_update_position_and_flip(is_player_flipped)

	# Lógica principal de apuntado y disparo.
	if current_mode == GunMode.TURRET:
		_update_turret_aim(is_player_flipped)
	else:
		rotation = base_rotation
		aim_angle = base_rotation

	_handle_input(is_player_flipped)


## --- LÓGICA INTERNA ---

func _handle_input(is_player_flipped: bool) -> void:
	match current_mode:
		GunMode.RAY:
			if Input.is_action_just_pressed("attack"):
				_start_ray()
			elif Input.is_action_just_released("attack"):
				_stop_ray()
		GunMode.PISTOL:
			if Input.is_action_pressed("fired") and can_fire:
				_fire_pistol(is_player_flipped)
		GunMode.TURRET:
			if Input.is_action_pressed("fired") and can_fire:
				_fire_turret()


func _update_position_and_flip(is_player_flipped: bool) -> void:
	# Calcula y aplica el offset de posición del arma.
	var offset = offset_left if is_player_flipped else offset_right
	if is_player_flipped:
		offset.x += extra_left_offset
	position = base_position + offset

	# Ajusta el flip del sprite del arma.
	if animated_sprite:
		if current_mode == GunMode.TURRET:
			animated_sprite.flip_h = false
			animated_sprite.flip_v = is_player_flipped
		else:
			animated_sprite.flip_h = is_player_flipped
			animated_sprite.flip_v = false


func _update_turret_aim(is_player_flipped: bool) -> void:
	var mouse_pos = get_global_mouse_position()
	var dir_to_mouse = global_position.direction_to(mouse_pos)

	var forward_dir = Vector2.LEFT if is_player_flipped else Vector2.RIGHT
	var forward_angle = forward_dir.angle()
	var target_angle = dir_to_mouse.angle()

	var relative_angle = wrapf(target_angle - forward_angle, -PI, PI)
	var clamped_relative_angle = clamp(relative_angle, -turret_angle_limit, turret_angle_limit)
	
	aim_angle = forward_angle + clamped_relative_angle
	rotation = aim_angle


## --- MODOS DE DISPARO ---

func _fire_pistol(is_flipped: bool) -> void:
	if animated_sprite: animated_sprite.play("idle")
	var direction = (Vector2.LEFT if is_flipped else Vector2.RIGHT).rotated(aim_angle)
	_spawn_bullet(direction)
	
	can_fire = false
	timer.wait_time = cooldown
	timer.start()


func _fire_turret() -> void:
	if animated_sprite and animated_sprite.animation != "metralleta":
		animated_sprite.play("metralleta")
	var direction = Vector2.RIGHT.rotated(aim_angle)
	_spawn_bullet(direction)
	
	can_fire = false
	timer.wait_time = turret_fire_rate
	timer.start()

# ==========================================
# RAYO
# ==========================================

func _start_ray() -> void:
	# Si ya hay un rayo, no hagas nada
	if current_ray != null:
		return
		
	var ray_instance = ray_scene.instantiate()
	if not ray_instance:
		push_error("La escena del rayo no está bien asignada.")
		return

		# ===== CAMBIO CLAVE =====
	# 1. Añade el rayo como HIJO del arma.
	# Esto hace que se mueva y rote junto al arma automáticamente.
	add_child(ray_instance)
	
	ray_instance.position = muzzle.position
	ray_instance.rotation = 0 # El láser hereda la rotación del arma.

	# 3. Llama a la nueva función para establecer la longitud del haz.
	if ray_instance.has_method("setup_beam"):
		# Usamos el valor por defecto del láser (max_range), que es 800.
		ray_instance.setup_beam(ray_instance.max_range)
	
	# 4. Inicia sus timers de duración y daño.
	if ray_instance.has_method("start"):
		ray_instance.start(ray_duration_max, ray_dmg, ray_dmg_reduction)
	
	# Guardar referencia y conectar la señal
	current_ray = ray_instance
	current_ray.connect("tree_exited", Callable(self, "_on_ray_removed"))


func _stop_ray() -> void:
	if current_ray != null:
		current_ray.queue_free()
		# El cooldown se activa cuando el rayo es eliminado en _on_ray_removed.


## --- FUNCIONES DE SOPORTE ---

func _spawn_bullet(direction: Vector2) -> void:
	if not bullet_scene:
		push_error("❌ La escena de la bala no está asignada en gun.gd.")
		return
		
	var bullet = bullet_scene.instantiate()
	# MEJORA: Considera tener un nodo "Projectiles" para mantener la escena limpia.
	get_tree().current_scene.add_child(bullet)
	# Usamos la posición GLOBAL del Muzzle para que la bala aparezca en la punta del cañón.
	bullet.global_position = muzzle.global_position
	bullet.rotation = direction.angle()
	
	# Pasa la dirección a la bala si tiene una variable o método para ello.
	if "direction" in bullet:
		bullet.direction = direction
	
	_apply_bullet_effects(bullet)


func _apply_bullet_effects(bullet: Node) -> void:
	if player and player.has_method("apply_power_to_bullet"):
		player.apply_power_to_bullet(bullet)


func _on_timer_timeout() -> void:
	can_fire = true


func _on_ray_removed() -> void:
	current_ray = null
	can_fire = false
	timer.wait_time = cooldown
	timer.start()


## --- INTERFAZ PÚBLICA ---

func set_mode(mode: GunMode) -> void:
	current_mode = mode
	can_fire = true
	timer.stop() # Detiene cualquier cooldown pendiente al cambiar de modo.
	
	# Reinicia rotación y animaciones.
	rotation = base_rotation
	aim_angle = base_rotation
	
	if not animated_sprite: return
	
	if current_mode == GunMode.TURRET:
		animated_sprite.play("metralleta")
	else:
		animated_sprite.play("idle")
		
