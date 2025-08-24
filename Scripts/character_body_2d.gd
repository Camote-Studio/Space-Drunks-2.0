extends CharacterBody2D

# Señal con 'source' opcional para no romper _on_damage
signal damage(value: float)

var speed := 400
@onready var bar: ProgressBar = $"../CanvasLayer/ProgressBar_alien_1"
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

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

func _ready() -> void:
	if not is_connected("damage", Callable(self, "_on_damage")):
		connect("damage", Callable(self, "_on_damage"))
	animated_sprite.play("idle")

func _physics_process(delta: float) -> void:
	# Si está muerto, no procesa entradas, física ni animaciones
	if dead:
		velocity = Vector2.ZERO
		return

	# Si está flotando por bala_gravedad, manejarlo y no mover por física normal
	if floating:
		_handle_floating(delta)
		return

	var direction := Vector2.ZERO
	if allow_input:
		direction = Input.get_vector("left_player_1", "right_player_1", "up_player_1", "down_player_1")

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

func _on_damage(amount: float, source: String = "") -> void:
	# Ignorar daño si ya está muerto
	if dead:
		return

	# Aplicar daño a la barra
	if bar:
		bar.value = clamp(bar.value - amount, bar.min_value, bar.max_value)

		# Chequear muerte inmediatamente
		if bar.value <= bar.min_value:
			_die()
			return

	# Efectos si sigue vivo
	if source == "bala":
		controls_inverted = true
		invert_timer = invert_duration
		print("jugador invertido por impacto de bala")
	elif source == "bala_gravedad":
		floating = true
		invulnerable = true
		invul_timer = invul_duration

func _on_damage_enemy_body_entered(body: Node2D) -> void:
	if body.is_in_group("gun_enemy"):
		# Pasa un 'source' explícito para que _on_damage sepa qué hacer
		emit_signal("damage", 20.0, "bala")

func _handle_floating(delta: float) -> void:
	var target_y: float
	var current_lerp_speed: float
	var current_rotation_speed: float

	if invul_timer > 0.0:
		target_y = float_target_y
		current_lerp_speed = float_lerp_speed
		current_rotation_speed = rotation_speed
		if is_in_group("player"):
			remove_from_group("player")
	else:
		target_y = float_start_y
		current_lerp_speed = return_lerp_speed
		current_rotation_speed = 0.0
		# Restaurar grupo cuando regresa
		if not is_in_group("player"):
			add_to_group("player")

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
	if is_in_group("player"):
		remove_from_group("player")

	# Animación de muerte (sin loop)
	if animated_sprite:
		$AnimationPlayer.play("explosion_death")
		animated_sprite.play("death")
		# Manejar el fin de la animación una sola vez
		if not animated_sprite.is_connected("animation_finished", Callable(self, "_on_death_finished")):
			animated_sprite.connect("animation_finished", Callable(self, "_on_death_finished"))

func _on_death_finished() -> void:
	# Asegurar que se quede en el último frame de "death"
	if animated_sprite.animation == "death":
		animated_sprite.playing = false
