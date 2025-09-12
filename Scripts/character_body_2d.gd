extends CharacterBody2D # player 1

signal damage(amount: float, source: String)
signal muerte
@onready var shop: Control = $"../CanvasLayer/UI_abilities"

var coins: int = 0
@export var player_id: String = "player1" # Identificador único

@onready var gun_node: Node = $Gun
@onready var sonido_aturdido: AudioStreamPlayer2D = $sonido_aturdido
@onready var sonido_flotando: AudioStreamPlayer2D = $sonido_flotando

@export var gun_360_scene: PackedScene = preload("res://Scenes/gun_360.tscn")
var _360_instance: Node2D = null
var _360_timer: Timer
var _360_active := false

@export var electro_gun_scene: PackedScene = preload("res://Scenes/electro_gun.tscn")
@export var electro_duration_min: float = 15.0
@export var electro_duration_max: float = 20.0
var _electro_instance: Node2D = null
var _revert_timer: Timer
var _electro_active := false

@onready var bar: TextureProgressBar = $"../CanvasLayer/ProgressBar_alien_1"
@onready var animated_sprite: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var bar_ability_1: ProgressBar = $"../CanvasLayer/ProgressBar_ability_1"
@onready var coin_label: Label = $"../CanvasLayer/cont monedas"

var has_chicken_pony := false
var has_jet_punches := false
var has_sleepy_gun := false
var speed := 200

enum Estado { NORMAL, VENENO, ATURDIDO }
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
var next_shot_powered := false
var power_bullet_scale := 1.8
var power_bullet_extra_damage := 20.0
@onready var visuals: Node2D = $Visuals

# ====== Variables de salto ======
@export var jump_force: float = 280.0
@export var gravity: float = 600.0
var z: float = 0.0
var z_velocity: float = 0.0
var is_jumping: bool = false

func _ready() -> void:
	coins = GameState.get_coins(player_id)
	GameState.set_coins(player_id, coins)

	if coin_label:
		coin_label.text = str(coins)
	else:
		push_error("⚠️ No se encontró el nodo Label de monedas en el árbol de nodos.")

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

	_360_timer = Timer.new()
	_360_timer.one_shot = true
	add_child(_360_timer)
	if not _360_timer.is_connected("timeout", Callable(self, "_360_gun_instance")):
		_360_timer.connect("timeout", Callable(self, "_360_gun_instance"))

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

			if not sonido_aturdido.playing:
				sonido_aturdido.play()

		Estado.NORMAL:
			if direction == Vector2.ZERO:
				animated_sprite.play("idle")
			else:
				if abs(direction.x) > abs(direction.y):
					animated_sprite.play("caminar")
					animated_sprite.flip_h = direction.x < 0
				elif direction.y < 0:
					animated_sprite.play("caminar_subir")

			if sonido_aturdido.playing:
				sonido_aturdido.stop()

	velocity = direction * speed

	# Input de salto
	if allow_input and not is_jumping and Input.is_action_just_pressed("jump") and not floating:
		z_velocity = jump_force
		is_jumping = true

	# Movimiento normal o flotante
	if not floating:
		if sonido_flotando.playing:
			sonido_flotando.stop()
		move_and_slide()
	else:
		if not sonido_flotando.playing:
			sonido_flotando.play()
		_handle_floating(delta)

	# ====== Física del salto ======
# ====== Física del salto ======
# ====== Física del salto ======
# ====== Física del salto ======
	if is_jumping:
		z_velocity -= gravity * delta
		z += z_velocity * delta

		if z <= 0.0:
			z = 0.0
			z_velocity = 0.0
			is_jumping = false

		# Elevar todo lo visual (sprite + pistola)
		visuals.position.y = -z
	else:
		# Reset al estar en el suelo
		visuals.position.y = 0




# ======================
# DAÑO
# ======================
func _on_damage(amount: float, source: String = "desconocido") -> void:
	if dead: return

	if bar:
		bar.value = clamp(bar.value - amount, bar.min_value, bar.max_value)
		if bar.value <= bar.min_value:
			_die()
			return

	match source:
		"veneno":
			if estado_actual == Estado.NORMAL:
				estado_actual = Estado.VENENO
				$venenoTimer.start(0.5)
				animated_sprite.play("envenenado")

		"bala":
			if estado_actual == Estado.NORMAL:
				estado_actual = Estado.ATURDIDO
				$AturdidoTimer.start(2)
				animated_sprite.play("aturdio")

		"bala_gravedad":
			floating = true
			invulnerable = true
			invul_timer = invul_duration

func _on_damage_enemy_body_entered(body: Node2D) -> void:
	if body.is_in_group("gun_enemy") and not invulnerable and not dead:
		emit_signal("damage", 20.0, "bala")

# ======================
# FLOTAR
# ======================
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
# CARGA DE HABILIDAD
# ======================
func gain_ability_from_attack(damage_dealt: float) -> void:
	if dead or bar_ability_1 == null: return
	var gain = max(0.0, damage_dealt)
	bar_ability_1.value = clamp(bar_ability_1.value + gain, bar_ability_1.min_value, bar_ability_1.max_value)
	if bar_ability_1.value >= bar_ability_1.max_value:
		_power()

func gain_ability_from_shot() -> void:
	if dead or bar_ability_1 == null: return
	var shots_required := 10.0
	var gain := (bar_ability_1.max_value - bar_ability_1.min_value) / shots_required
	bar_ability_1.value = clamp(bar_ability_1.value + gain, bar_ability_1.min_value, bar_ability_1.max_value)
	if bar_ability_1.value >= bar_ability_1.max_value:
		_power()

# ======================
# PODER
# ======================
func _power() -> void:
	if dead or next_shot_powered: 
		return
	if bar_ability_1 and bar_ability_1.value >= bar_ability_1.max_value:
		next_shot_powered = true
		bar_ability_1.value = bar_ability_1.min_value

func apply_power_to_bullet(bullet: Node) -> void:
	if not next_shot_powered: 
		return

	if bullet is Node2D:
		bullet.scale *= power_bullet_scale
	if "damage" in bullet:
		bullet.damage += power_bullet_extra_damage
	elif bullet.has_method("set_damage"):
		bullet.call("set_damage", power_bullet_extra_damage)

	next_shot_powered = false

# ======================
# MUERTE
# ======================
func _die() -> void:
	if _electro_active:
		_revert_gun_instance()
	elif _360_active:
		_360_gun_instance()

	dead = true
	allow_input = false
	floating = false
	invulnerable = false
	velocity = Vector2.ZERO
	rotation = 0.0

	set_collision_layer(0)
	set_collision_mask(0)

	if is_in_group("player"):
		remove_from_group("player")
	if is_in_group("players"):
		remove_from_group("players")

	if animated_sprite:
		animated_sprite.play("death")
		if not animated_sprite.is_connected("animation_finished", Callable(self, "_on_death_finished")):
			animated_sprite.connect("animation_finished", Callable(self, "_on_death_finished"))

	$"../CanvasLayer/Sprite2D".self_modulate = Color(1, 0, 0, 1)
	$"../CanvasLayer/Characater1Profile".texture = preload("res://Assets/art/sprites/complements_sprites/muerto_kirk.png")
	emit_signal("muerte")

func _on_death_finished() -> void:
	if animated_sprite.animation == "death":
		animated_sprite.playing = false

func _on_aturdido_timer_timeout() -> void:
	if estado_actual == Estado.ATURDIDO:
		estado_actual = Estado.NORMAL
		if sonido_aturdido.playing:
			sonido_aturdido.stop()

func _on_veneno_timer_timeout() -> void:
	if estado_actual == Estado.VENENO:
		estado_actual = Estado.NORMAL

# ======================
# MONEDAS
# ======================
func collect_coin(amount: int = 1) -> void:
	coins += amount
	if coin_label:
		coin_label.text = str(coins)
	GameState.set_coins(player_id, coins)
	if coins >= 20:
		_show_shop()
		coins = 0
		if coin_label:
			coin_label.text = str(coins)
			GameState.set_coins(player_id, coins)

# ======================
# ARMAS ESPECIALES
# ======================
func activate_electro_for(seconds: float = -1.0) -> void:
	if seconds <= 0.0:
		seconds = randf_range(electro_duration_min, electro_duration_max)
	if electro_gun_scene == null:
		push_warning("[P1] electro_gun_scene no asignada.")
		return
	if _electro_active and is_instance_valid(_electro_instance):
		_revert_timer.start(seconds)
		return

	_electro_instance = electro_gun_scene.instantiate() as Node2D
	add_child(_electro_instance)
	_electro_instance.name = "ElectroGun"
	_electro_instance.position = gun_node.position

	_set_gun_active(gun_node, false)
	_set_gun_active(_electro_instance, true)
	_electro_active = true
	_revert_timer.start(seconds)

func _revert_gun_instance() -> void:
	if is_instance_valid(_electro_instance):
		_set_gun_active(_electro_instance, false)
		_electro_instance.queue_free()
		_electro_instance = null
		_electro_active = false
	_set_gun_active(gun_node, true)

func activate_360_for(seconds: float = -1.0) -> void:
	if seconds <= 0.0:
		seconds = randf_range(electro_duration_min, electro_duration_max)
	if gun_360_scene == null:
		push_warning("[P1] 360_gun_scene no asignada.")
		return
	if _360_active and is_instance_valid(_360_instance):
		_360_timer.start(seconds)
		return

	_360_instance = gun_360_scene.instantiate() as Node2D
	add_child(_360_instance)
	_360_instance.name = "360Gun"
	_360_instance.position = gun_node.position

	_set_gun_active(gun_node, false)
	_set_gun_active(_360_instance, true)
	_360_active = true
	_360_timer.start(seconds)

func _360_gun_instance() -> void:
	if is_instance_valid(_360_instance):
		_set_gun_active(_360_instance, false)
		_360_instance.queue_free()
		_360_instance = null
		_360_active = false
	_set_gun_active(gun_node, true)

func _set_gun_active(g: Node, active: bool) -> void:
	if not is_instance_valid(g): return
	g.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	if "visible" in g:
		g.visible = active

func _show_shop() -> void:
	if shop:
		shop.open_for(self)
	else:
		push_warning("[P1] No encontré la tienda (UI_abilities)")
