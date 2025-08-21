extends CharacterBody2D

var speed := 300
var player: CharacterBody2D = null
const BULLET_ENEMY_1 = preload("res://TSCN/gun_enemy_1.tscn")

# --- Parámetros de comportamiento ---
var min_range := 250.0      # si está más cerca que esto, se aleja
var max_range := 350.0      # si está más lejos que esto, se acerca
var attack_range := 500.0   # solo dispara si el jugador está dentro de este rango

# --- Parámetros del disparo ---
var bullet_speed := 700.0   # velocidad de la bala

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	$gun_timer.start()

func _physics_process(delta: float) -> void:
	follow_player(delta)

func follow_player(delta: float) -> void:
	if player == null:
		return

	# Vector hacia el jugador
	var to_player: Vector2 = player.global_position - global_position
	var dist := to_player.length()

	# Mira hacia el jugador
	look_at(player.global_position)
	rotation_degrees = wrap(rotation_degrees,0,360)

	# Mantenerse dentro del “anillo” [min_range, max_range]
	if dist > max_range:
		velocity = to_player.normalized() * speed          # acercarse
	elif dist < min_range:
		velocity = -to_player.normalized() * speed         # alejarse
	else:
		velocity = Vector2.ZERO                            # quedarse en rango

	move_and_slide()

func _on_gun_timer_timeout() -> void:
	if player == null:
		return

	# Solo dispara si el jugador está a distancia razonable
	var to_player: Vector2 = player.global_position - global_position
	if to_player.length() > attack_range:
		return

	var bullet_instance = BULLET_ENEMY_1.instantiate()
	get_parent().add_child(bullet_instance)
	bullet_instance.global_position = global_position
	bullet_instance.rotation = to_player.angle()
