extends CharacterBody2D

signal damage(amount: float, source: String)
signal muerte  

@onready var bar: ProgressBar = $"../CanvasLayer/ProgressBar_alien_1"
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var speed := 200
enum Estado {
	NORMAL,
	VENENO,
	ATURDIDO
}
var estado_actual : Estado = Estado.NORMAL
var floating := false
var invulnerable := false
var invul_duration := 4.3
var invul_timer := 0.0
var float_start_y := 420.0
var float_target_y := 130.0
var rotation_speed := 3.0
var float_lerp_speed := 2.5
var return_lerp_speed := 3.0

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
		direction = Input.get_vector("left_player_1", "right_player_1", "up_player_1", "down_player_1")

	match estado_actual:
		Estado.VENENO:
			if animated_sprite.animation != "envenenado":
				animated_sprite.play("envenenado")
			if abs(direction.x) > 0:
				animated_sprite.flip_h = direction.x < 0

		Estado.ATURDIDO:
			direction = -direction
			if animated_sprite.animation != "aturdio":
				animated_sprite.play("aturdio")
			if abs(direction.x) > abs(direction.y):
				animated_sprite.flip_h = direction.x < 0

		Estado.NORMAL:
			if direction == Vector2.ZERO:
				animated_sprite.play("idle")
			else:
				if abs(direction.x) > abs(direction.y):
					animated_sprite.play("caminar")
					animated_sprite.flip_h = direction.x < 0
				elif direction.y < 0:
					animated_sprite.play("caminar_subir")
				else:
					animated_sprite.play("caminar_bajar")

	velocity = direction * speed

	if not floating:
		move_and_slide()
	else:
		_handle_floating(delta)

func _on_damage(amount: float, source: String = "desconocido") -> void:
	if dead:
		return

	if bar:
		bar.value = clamp(bar.value - amount, bar.min_value, bar.max_value)
		if bar.value <= bar.min_value:
			_die()
			return

	match source:
		"veneno":
			if estado_actual == Estado.NORMAL:   
				print("🔥 Jugador envenenado")
				estado_actual = Estado.VENENO
				$venenoTimer.start(0.5)
				animated_sprite.play("envenenado")

		"bala":
			if estado_actual == Estado.NORMAL:   
				print("💥 Jugador aturdido")
				estado_actual = Estado.ATURDIDO
				$AturdidoTimer.start(2)
				animated_sprite.play("aturdio")

		"bala_gravedad":
			print("🌪 Jugador flotando")
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
		if is_in_group("player"):
			remove_from_group("player")
	else:
		target_y = float_start_y
		current_lerp_speed = return_lerp_speed
		current_rotation_speed = 0.0
		if not is_in_group("player"):
			add_to_group("player")

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

	velocity = Vector2.ZERO
	rotation = 0.0

	# Sin colisiones ni daños posteriores
	set_collision_layer(0)
	set_collision_mask(0)

	# Salir de grupo de jugadores
	if is_in_group("player"):
		remove_from_group("player")
	if is_in_group("players"):
		remove_from_group("players")

	# Animación de muerte
	if animated_sprite:
		animated_sprite.play("death")
		if not animated_sprite.is_connected("animation_finished", Callable(self, "_on_death_finished")):
			animated_sprite.connect("animation_finished", Callable(self, "_on_death_finished"))

	# Emitir señal para GameManager
	emit_signal("muerte")

func _on_death_finished() -> void:
	if animated_sprite.animation == "death":
		animated_sprite.playing = false


func _on_aturdido_timer_timeout() -> void:
	if estado_actual == Estado.ATURDIDO:
		estado_actual = Estado.NORMAL

func _on_veneno_timer_timeout() -> void:
	if estado_actual == Estado.VENENO:
		estado_actual = Estado.NORMAL
