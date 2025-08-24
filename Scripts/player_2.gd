extends CharacterBody2D

signal damage(value: float)

# --- Variables de movimiento ---
var speed := 400
var controls_inverted := false
var invert_duration := 2.0
var invert_timer := 0.0

var floating := false
var invulnerable := false
var invul_duration := 4.0
var invul_timer := 0.0
var float_start_y := 420.0
var float_target_y := 130.0
var rotation_speed := 3.0
var float_lerp_speed := 2.0
var return_lerp_speed := 3.0 

# --- Nodos ---
@onready var bar_2: ProgressBar = $"../CanvasLayer/ProgressBar_alien_2"
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# --- Funciones de Godot ---
func _ready() -> void:
	if not is_connected("damage", Callable(self, "_on_damage")):
		connect("damage", Callable(self, "_on_damage"))
	animated_sprite.play("idle")

func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("left_player_2", "right_player_2", "up_player_2", "down_player_2")
	
	# Invertir controles si es necesario
	if controls_inverted:
		direction.x = -direction.x
		direction.y = -direction.y
		invert_timer -= delta
		if invert_timer <= 0.0:
			controls_inverted = false

	velocity = direction * speed
	if direction == Vector2.ZERO:
		animated_sprite.play("idle")
	else:
		animated_sprite.play("caminar")  # 👈 tu animación de caminar
		if abs(direction.x) > 0.05:
			animated_sprite.flip_h = direction.x < 0
	

	# Flip horizontal al moverse a la izquierda/derecha


	# Movimiento normal o flotante
	if not floating:
		move_and_slide()
	else:
		_handle_floating(delta)

# --- Función de flotación ---
func _handle_floating(delta: float) -> void:
	var target_y
	var current_lerp_speed
	var current_rotation_speed
	if invul_timer > 0:
		target_y = float_target_y
		current_lerp_speed = float_lerp_speed
		current_rotation_speed = rotation_speed
		if is_in_group("player_2"):
			remove_from_group("player_2")
	else:
		target_y = float_start_y
		current_lerp_speed = return_lerp_speed
		current_rotation_speed = 0.0
		# Restaurar grupo cuando regresa
		if not is_in_group("player_2"):
			add_to_group("player_2")

	# Movimiento vertical y rotación
	global_position.y = lerp(global_position.y, target_y, current_lerp_speed * delta)
	rotation += current_rotation_speed * delta

	# Desactivar colisiones mientras flota
	set_collision_layer(0)
	set_collision_mask(0)

	# Reducir timer de invulnerabilidad
	invul_timer -= delta

	# Terminar efecto al regresar completamente
	if invul_timer <= 0.0 and abs(global_position.y - float_start_y) < 1.0:
		floating = false
		invulnerable = false
		rotation = 0
		global_position.y = float_start_y
		set_collision_layer(1)
		set_collision_mask(1)

# --- Función que recibe daño ---
func _on_damage(amount: float, source: String) -> void:
	if bar_2:
		bar_2.value = clamp(bar_2.value - amount, bar_2.min_value, bar_2.max_value)

	if source == "bala":
		# Solo si el daño viene de una bala normal
		controls_inverted = true
		invert_timer = invert_duration
		print("Jugador invertido por impacto de bala")
	elif source == "bala_gravedad":
		floating = true
		invulnerable = true
		invul_timer = invul_duration

# --- Función para colisiones con enemigos ---
func _on_damage_enemy_body_entered(body: Node2D) -> void:
	if body.is_in_group("gun_enemy") and not invulnerable:
		emit_signal("damage", 20.0)
