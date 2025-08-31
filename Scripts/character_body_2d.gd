extends CharacterBody2D
# player 1
signal damage(amount: float, source: String)
signal muerte  
var coins: int = 0

@onready var gun_node: Node = $Gun

@export var gun_360_scene: PackedScene = preload("res://Scenes/gun_360.tscn")

@export var electro_gun_scene: PackedScene = preload("res://Scenes/electro_gun.tscn")
@export var electro_duration_min: float = 15.0
@export var electro_duration_max: float = 20.0

var _electro_instance: Node2D = null
var _revert_timer: Timer
var _electro_active := false

@onready var bar: TextureProgressBar = $"../CanvasLayer/ProgressBar_alien_1"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var bar_ability_1: ProgressBar = $"../CanvasLayer/ProgressBar_ability_1"

@onready var shop: Control = $"../CanvasLayer/UI_abilities"

var has_chicken_pony := false
var has_jet_punches := false
var has_sleepy_gun := false

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

# ====== Poder de disparo potenciado ======
var next_shot_powered := false         # se activa cuando la barra se llena
var power_bullet_scale := 1.8          # escala visual del próximo disparo
var power_bullet_extra_damage := 20.0  # daño extra del próximo disparo

func _ready() -> void:
	if not is_connected("damage", Callable(self, "_on_damage")):
		connect("damage", Callable(self, "_on_damage"))
	animated_sprite.play("idle")
	if not is_in_group("players"):
		add_to_group("players")
	_revert_timer = Timer.new()
	_revert_timer.one_shot = true
	add_child(_revert_timer)
	
	if not _revert_timer.is_connected("timeout", Callable(self, "_revert_gun_instance")):
		_revert_timer.connect("timeout", Callable(self, "_revert_gun_instance"))

	_set_gun_active(gun_node, true)
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


	velocity = direction * speed

	if not floating:
		move_and_slide()
	else:
		_handle_floating(delta)

func _on_damage(amount: float, source: String = "desconocido") -> void:
	if dead:
		return

	# --- Vida (recibir daño) ---
	if bar:
		bar.value = clamp(bar.value - amount, bar.min_value, bar.max_value)
		if bar.value <= bar.min_value:
			_die()
			return

	# IMPORTANTE: Ya NO cargamos la barra de habilidad al recibir daño.
	# La barra se carga SOLO cuando el jugador HACE daño (ver gain_ability_from_attack).

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
#  CARGA DE HABILIDAD (por atacar)
# ======================
# Llama este método DESDE tu bala/ataque al impactar a un enemigo.
func gain_ability_from_attack(damage_dealt: float) -> void:
	if dead or bar_ability_1 == null:
		return
	# Suma en función del daño infligido (ajusta si quieres otro ritmo)
	var gain = max(0.0, damage_dealt)
	bar_ability_1.value = clamp(bar_ability_1.value + gain, bar_ability_1.min_value, bar_ability_1.max_value)
	if bar_ability_1.value >= bar_ability_1.max_value:
		_power()

# ======================
#        PODER
# ======================
# Activa el "próximo disparo potenciado" y resetea la barra.
func _power() -> void:
	if dead: return
	if next_shot_powered: return
	if bar_ability_1 and bar_ability_1.value >= bar_ability_1.max_value:
		next_shot_powered = true
		bar_ability_1.value = bar_ability_1.min_value
		print("⚡ ¡Poder activado! El próximo disparo será potenciado")

# Aplica el poder a la bala recién creada (llámalo al instanciar la bala del jugador).
func apply_power_to_bullet(bullet: Node) -> void:
	if not next_shot_powered:
		return
	# Escalar visualmente
	if bullet is Node2D:
		bullet.scale *= power_bullet_scale
	# Añadir daño extra si la bala lo soporta
	if "damage" in bullet:
		bullet.damage += power_bullet_extra_damage
	elif bullet.has_method("set_damage"):
		bullet.call("set_damage", power_bullet_extra_damage)
	# Consumir el poder (solo este disparo)
	next_shot_powered = false
	print("💥 Disparo potenciado lanzado")

# ======================
#        MUERTE
# ======================
func _die() -> void:
	if _electro_active:
		_revert_gun_instance()
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
		
func collect_coin() -> void:
	coins += 1
	$"../CanvasLayer/cont monedas2".text=str(coins)
	# Cuando llega a 1 moneda, muestra el panel
	if coins == 1 and is_instance_valid(shop):
		shop.visible = true
func activate_electro_for(seconds: float = -1.0) -> void:
	if seconds <= 0.0:
		seconds = randf_range(electro_duration_min, electro_duration_max)
	if electro_gun_scene == null:
		push_warning("[P1] electro_gun_scene no asignada.")
		return
	# Si ya está activa, solo extiende el tiempo
	if _electro_active and is_instance_valid(_electro_instance):
		_revert_timer.start(seconds)
		print("[P1] ⏱ ElectroGun extendida a ", seconds, "s")
		return

	# Instanciar ElectroGun como hija del player
	_electro_instance = electro_gun_scene.instantiate() as Node2D
	add_child(_electro_instance)
	_electro_instance.name = "ElectroGun"
	# opcional: copia posición para que “aparezca” en el mismo sitio que la normal
	_electro_instance.position = gun_node.position

	# Activa electro, desactiva normal
	_set_gun_active(gun_node, false)
	_set_gun_active(_electro_instance, true)
	_electro_active = true
	_revert_timer.start(seconds)
	print("[P1] ✅ ElectroGun ACTIVADA por ", seconds, "s")
func _revert_gun_instance() -> void:
	# Apaga y borra ElectroGun
	if is_instance_valid(_electro_instance):
		_set_gun_active(_electro_instance, false)
		_electro_instance.queue_free()
		_electro_instance = null
		_electro_active = false

	# Reactiva la normal
	_set_gun_active(gun_node, true)
	print("[P1] 🔁 Vuelve la Gun normal")

func _set_gun_active(g: Node, active: bool) -> void:
	if not is_instance_valid(g):
		return
	# que solo procese el arma activa
	g.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	if "visible" in g:
		g.visible = active
