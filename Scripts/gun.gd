extends Node2D

@export var bullet_scene: PackedScene = preload("res://Scenes/bullet.tscn")
@export var cooldown: float = 0.5
var can_fire := true

@onready var timer: Timer = $Timer
var pitch_variations_gun = [0.8, 1.0, 1.5]

# Offset del gun respecto al jugador
@export var offset_right := Vector2(10, 15)
@export var offset_left := Vector2(-10, 15)

# Referencias
var player: Node2D
var player_sprite: AnimatedSprite2D
var visuals_node: Node2D
var base_position: Vector2

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

func _process(delta: float) -> void:
	if not player:
		return

	var flipped := player_sprite and player_sprite.flip_h

	# Actualizar sprite y posición del gun
	$Sprite2D.flip_h = flipped
	position.x = base_position.x + (offset_left.x if flipped else offset_right.x)
	position.y = visuals_node.position.y + (offset_left.y if flipped else offset_right.y) if visuals_node else (offset_left.y if flipped else offset_right.y)

	# Si el jugador no puede disparar
	if "dead" in player and player.dead:
		return
	if "allow_input" in player and not player.allow_input:
		return

	if Input.is_action_just_pressed("fired") and can_fire:
		_fire(flipped)

func _fire(is_flipped: bool) -> void:
	if has_node("lasergun"):
		$lasergun.pitch_scale = pitch_variations_gun[randi() % pitch_variations_gun.size()]
		$lasergun.play()

	# Instanciar bala
	var bullet_instance = bullet_scene.instantiate()
	if bullet_instance == null:
		push_error("❌ bullet_scene no está bien asignado. Revisa la ruta en preload.")
		return

	# Agregarla al árbol ANTES de usar global_position
	get_tree().current_scene.add_child(bullet_instance)

	# Configurar posición y dirección
	bullet_instance.global_position = global_position
	bullet_instance.direction = Vector2.LEFT if is_flipped else Vector2.RIGHT
	bullet_instance.rotation = bullet_instance.direction.angle()

	# Pasar datos extra al player
	if player:
		if player.has_method("apply_power_to_bullet"):
			player.apply_power_to_bullet(bullet_instance)
		if player.has_method("gain_ability_from_shot"):
			player.gain_ability_from_shot()

	can_fire = false
	timer.start()

func _on_timer_timeout() -> void:
	can_fire = true
