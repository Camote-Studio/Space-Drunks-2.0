extends Node2D

@export var bullet_scene: PackedScene = preload("res://Scenes/bullet.tscn")

var can_fire := true
@export var cooldown: float = 0.5
@onready var timer: Timer = $Timer
var pitch_variations_gun = [0.8, 1.0, 1.5]

# Offset más pegado al jugador
@export var offset_right := Vector2(10, 15)
@export var offset_left := Vector2(-10, 15)

# referencias (se inicializan en _ready)
var player = null
var player_sprite: AnimatedSprite2D = null
var visuals_node: Node2D = null
var base_position: Vector2

func _ready() -> void:
	# Timer
	timer.one_shot = true
	timer.wait_time = cooldown
	if not timer.is_connected("timeout", Callable(self, "_on_timer_timeout")):
		timer.connect("timeout", Callable(self, "_on_timer_timeout"))

	# Parent (debe ser el Player)
	player = get_parent()
	# Intentar obtener Visuals/AnimatedSprite2D si existe
	if player:
		if player.has_node("Visuals"):
			visuals_node = player.get_node("Visuals")
			if visuals_node and visuals_node.has_node("AnimatedSprite2D"):
				player_sprite = visuals_node.get_node("AnimatedSprite2D")
		elif player.has_node("AnimatedSprite2D"):
			# caso antiguo: sprite directo hijo del player
			player_sprite = player.get_node("AnimatedSprite2D")

	# Guardar la posición local original para respetar offsets
	base_position = position

func random_pitch_variations_gun() -> void:
	if has_node("lasergun"):
		var random_pitch = pitch_variations_gun[randi() % pitch_variations_gun.size()]
		$lasergun.pitch_scale = random_pitch
		$lasergun.play()

func _process(delta: float) -> void:
	# Asegurarnos de tener referencia al player
	if player == null:
		player = get_parent()
		if player == null:
			return

	# Determinar si el sprite está flip_h (buscar dinámicamente si hace falta)
	var flipped := false
	if player_sprite:
		flipped = player_sprite.flip_h
	else:
		# intento de recuperación si el sprite cambió después
		if player.has_node("Visuals/AnimatedSprite2D"):
			player_sprite = player.get_node("Visuals/AnimatedSprite2D")
			flipped = player_sprite.flip_h
		elif player.has_node("AnimatedSprite2D"):
			player_sprite = player.get_node("AnimatedSprite2D")
			flipped = player_sprite.flip_h

	# Actualizar flip y offsets horizontales
	$Sprite2D.flip_h = flipped
	position.x = base_position.x + (offset_left.x if flipped else offset_right.x)

	# Calcular Y en base al offset y al salto de Visuals
	var offset_y := (offset_left.y if flipped else offset_right.y)
	if visuals_node:
		position.y = visuals_node.position.y + offset_y
	else:
		position.y = offset_y

	# Comprobaciones seguras de estado del jugador (evitar errores si no existen propiedades)
	if "dead" in player and player.dead:
		return
	if "allow_input" in player and not player.allow_input:
		return

	# Disparo
	if Input.is_action_just_pressed("fired") and can_fire:
		_fire(flipped)

func _fire(is_flipped: bool) -> void:
	random_pitch_variations_gun()
	var bullet_instance = bullet_scene.instantiate()

	# Añadir la bala al mismo nivel que el jugador (escena padre del Player)
	var world = null
	if get_parent() and get_parent().get_parent():
		world = get_parent().get_parent()
	else:
		world = get_tree().get_current_scene()
	world.add_child(bullet_instance)

	# Posicionar la bala en la posición global de la boca del cañón (global_position del gun)
	bullet_instance.global_position = global_position

	# Ajustar rotación de la bala según flip
	bullet_instance.rotation_degrees = 180 if is_flipped else 0

	# Aplicar potencia si el jugador lo implementa
	if player and player.has_method("apply_power_to_bullet"):
		player.apply_power_to_bullet(bullet_instance)

	# Cargar la barra por disparo si el player tiene esa función
	if player and player.has_method("gain_ability_from_shot"):
		player.gain_ability_from_shot()

	can_fire = false
	timer.start()

func _on_timer_timeout() -> void:
	can_fire = true
