extends CharacterBody2D

# --- Señales ---
signal damage(amount: float, source: String)
signal muerte  # Para notificar al GameManager

# --- Nodos ---
@onready var bar: ProgressBar = $"../CanvasLayer/ProgressBar_alien_2"
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# --- Movimiento ---
var speed := 220
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

# --- Estado ---
var dead := false
var allow_input := true

func _ready() -> void:
	if not is_connected("damage", Callable(self, "_on_damage")):
		connect("damage", Callable(self, "_on_damage"))
	animated_sprite.play("idle")
	if not is_in_group("players"):
		add_to_group("players")

func _physics_process(delta: float) -> void:
	if dead:
		velocity = Vector2.ZERO
		return

	var direction = Vector2.ZERO
	if allow_input:
		direction = Input.get_vector("left_player_2", "right_player_2", "up_player_2", "down_player_2")

	if controls_inverted:
		direction = -direction
		invert_timer -= delta
		if invert_timer <= 0.0:
			controls_inverted = false

	velocity = direction * speed

	# Animaciones
	if direction == Vector2.ZERO:
		animated_sprite.play("idle")
	else:
		if abs(direction.x) > abs(direction.y):
			animated_sprite.play("caminar")
			animated_sprite.flip_h = direction.x < 0
		elif direction.y < 0:
			animated_sprite.play("caminar_subir")
		elif direction.y > 0:
			animated_sprite.play("caminar_bajar")

	if not floating:
		move_and_slide()
	else:
		_handle_floating(delta)

func _on_damage(amount: float, source: String) -> void:
	if dead:
		return

	if bar:
		bar.value = clamp(bar.value - amount, bar.min_value, bar.max_value)
		if bar.value <= bar.min_value:
			_die()
			return

	if source == "bala":
		controls_inverted = true
		invert_timer = invert_duration
		print("Jugador invertido por impacto de bala")
	elif source == "bala_gravedad":
		floating = true
		invulnerable = true
		invul_timer = invul_duration

func _on_damage_enemy_body_entered(body: Node2D) -> void:
	if body.is_in_group("gun_enemy") and not invulnerable and not dead:
		emit_signal("damage", 20.0, "bala")

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
		if not is_in_group("player_2"):
			add_to_group("player_2")

	global_position.y = lerp(global_position.y, target_y, current_lerp_speed * delta)
	rotation += current_rotation_speed * delta

	set_collision_layer(0)
	set_collision_mask(0)

	invul_timer -= delta

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

	set_collision_layer(0)
	set_collision_mask(0)

	if is_in_group("player_2"):
		remove_from_group("player_2")
	if is_in_group("players"):
		remove_from_group("players")

	if animated_sprite:
		animated_sprite.play("death")
		if not animated_sprite.is_connected("animation_finished", Callable(self, "_on_death_finished")):
			animated_sprite.connect("animation_finished", Callable(self, "_on_death_finished"))

	emit_signal("muerte")

func _on_death_finished() -> void:
	if animated_sprite.animation == "death":
		animated_sprite.playing = false
