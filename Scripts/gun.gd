extends Node2D

@export var bullet_scene: PackedScene = preload("res://Scenes/bullet.tscn")

var can_fire := true
@export var cooldown: float = 0.5
@onready var timer: Timer = $Timer
var pitch_variations_gun = [0.8, 1.0, 1.5]

# Offset para cuando apunta a la derecha e izquierda
@export var offset_right := Vector2(20, 20)
@export var offset_left := Vector2(-20, 20)

func _ready() -> void:
	timer.one_shot = true
	timer.wait_time = cooldown

func random_pitch_variations_gun():
	var random_pitch = pitch_variations_gun[randi() % pitch_variations_gun.size()]
	$lasergun.pitch_scale = random_pitch
	$lasergun.play()

func _process(delta: float) -> void:
	var player = get_parent()  # referencia al Player
	var player_sprite_is_flipped = player.get_node("AnimatedSprite2D").flip_h
	
	# **Cambiar posición y rotación en base al flip**
	$Sprite2D.flip_h = player_sprite_is_flipped
	position = offset_left if player_sprite_is_flipped else offset_right

	# --- Bloqueo de disparo si el jugador está muerto o sin input ---
	if player.dead or not player.allow_input:
		return

	if Input.is_action_just_pressed("fired") and can_fire:
		_fire(player_sprite_is_flipped)

func _fire(is_flipped: bool) -> void:
	random_pitch_variations_gun()
	var bullet_instance = bullet_scene.instantiate()

	# Añadir la bala al mismo nivel que el jugador
	get_parent().get_parent().add_child(bullet_instance)
	bullet_instance.global_position = global_position
	
	# Ajustar rotación de la bala
	bullet_instance.rotation_degrees = 180 if is_flipped else 0

	# 🚀 APLICAR EL PODER (muy importante)
	var player = get_parent()
	if player and player.has_method("apply_power_to_bullet"):
		player.apply_power_to_bullet(bullet_instance)

	# 🚀 Cargar la barra por disparo
	if player and player.has_method("gain_ability_from_shot"):
		player.gain_ability_from_shot()

	can_fire = false
	timer.start()


func _on_timer_timeout() -> void:
	can_fire = true
