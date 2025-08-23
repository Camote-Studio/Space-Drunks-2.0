extends Node2D

const BULLET = preload("res://Scenes/bullet.tscn")
var can_fire := true
@export var cooldown: float = 0.2
@onready var timer: Timer = $Timer
var pitch_variations_gun = [0.8, 1.0, 1.5]

func _ready() -> void:
	$Timer.one_shot = true
	$Timer.wait_time = cooldown

func random_pitch_variations_gun():
	var random_pitch = pitch_variations_gun[randi()%pitch_variations_gun.size()]
	$lasergun.pitch_scale = random_pitch
	$lasergun.play()

func _process(delta: float) -> void:
	# Ahora volteamos el sprite del arma en base a si el sprite del jugador está volteado.
	# get_parent().get_node("Sprite2D") accede al nodo del sprite del jugador.
	var player_sprite_is_flipped = get_parent().get_node("Sprite2D").flip_h
	
	# Simplemente asigna el valor de flip_h del jugador al sprite del arma.
	$Sprite2D.flip_h = player_sprite_is_flipped

	if Input.is_action_just_pressed("fired") and can_fire:
		random_pitch_variations_gun()
		var bullet_instance = BULLET.instantiate()
		get_tree().root.add_child(bullet_instance)

		bullet_instance.global_position = global_position
		
		# La rotación de la bala debe coincidir con la dirección de la escala del jugador.
		if player_sprite_is_flipped:
			bullet_instance.rotation_degrees = 180
		else:
			bullet_instance.rotation_degrees = 0
			
		can_fire = false
		$Timer.start()


func _on_timer_timeout() -> void:
	can_fire = true
