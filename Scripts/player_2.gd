extends CharacterBody2D

# Señal con 'source' opcional para no romper _on_damage
signal damage(value: float)
signal muerte

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

# --- Estado de muerte ---
var dead := false
var allow_input := true

# --- Nodos ---
@onready var bar_2: ProgressBar = $"../CanvasLayer/ProgressBar_alien_2"
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# --- Funciones de Godot ---
func _ready() -> void:
	if not is_connected("damage", Callable(self, "_on_damage")):
		connect("damage", Callable(self, "_on_damage"))
	animated_sprite.play("idle")
	
func _physics_process(delta: float) -> void:
	# Si está muerto, no procesa nada de movimiento ni animación
	if dead:
		velocity = Vector2.ZERO
		return

	# Si está en estado flotante, maneja flotación y corta el resto
	if floating:
		_handle_floating(delta)
		return

	var direction := Vector2.ZERO
	if allow_input:
		direction = Input.get_vector("left_player_2", "right_player_2", "up_player_2", "down_player_2")
	
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
		animated_sprite.play("caminar")
		if abs(direction.x) > 0.05:
			animated_sprite.flip_h = direction.x < 0

	move_and_slide()

# --- Función de flotación ---
func _handle_floating(delta: float) -> void:
	var target_y: float
	var current_lerp_speed: float
	var current_rotation_speed: float
	if invul_timer > 0.0:
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
		rotation = 0.0
		global_position.y = float_start_y
		set_collision_layer(1)
		set_collision_mask(1)

# --- Función que recibe daño ---
func _on_damage(amount: float, source: String = "") -> void:
	# Ignorar si ya está muerto
	if dead :
		return

	if bar_2:
		bar_2.value = clamp(bar_2.value - amount, bar_2.min_value, bar_2.max_value)
		# Chequear muerte inmediatamente
		if bar_2.value <= bar_2.min_value:
			_die()
			return

	# Efectos si sigue vivo
	if source == "bala":
		controls_inverted = true
		invert_timer = invert_duration
		print("Jugador invertido por impacto de bala")
	elif source == "bala_gravedad":
		floating = true
		invulnerable = true
		invul_timer = invul_duration

# --- Función para colisiones con enemigos ---
func _on_damage_enemy_body_entered(body: Node2D) -> void:
	if body.is_in_group("gun_enemy") and not invulnerable and not dead:
		# Pasa un 'source' explícito
		emit_signal("damage", 20.0, "bala")

# ======================
#        MUERTE
# ======================
func _die() -> void:
	dead = true
	allow_input = false
	floating = false
	invulnerable = false
	controls_inverted = false

	velocity = Vector2.ZERO
	rotation = 0.0

	# Sin colisiones ni daños posteriores
	set_collision_layer(0)
	set_collision_mask(0)

	# Salir de grupos de jugador
	if is_in_group("player_2"):
		remove_from_group("player_2")

	# Animación de muerte (sin loop)
	if animated_sprite:
		#$AnimationPlayer.play("explosion_death")
		animated_sprite.play("death")
		if not animated_sprite.is_connected("animation_finished", Callable(self, "_on_death_finished")):
			animated_sprite.connect("animation_finished", Callable(self, "_on_death_finished"))
			
	if is_in_group("players"):
		remove_from_group("players")
		
	emit_signal("muerte")  # Notifica al GameManager
		

func _on_death_finished() -> void:
	# Asegurar que se quede en el último frame de "death"
	if animated_sprite.animation == "death":
		animated_sprite.playing = false
