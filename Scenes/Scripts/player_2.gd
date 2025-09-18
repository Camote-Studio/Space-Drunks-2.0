extends CharacterBody2D
# player 2

# --- Señales ---
signal damage(amount: float, source: String)
signal muerte  # Para notificar al GameManager
# ============================
# PODER: ÁREA DE VENENO
# ============================
@export var poison_area_scene: PackedScene
var poison_preview: Node2D = null
var selecting_poison := false

# --- Variables ---
var coins: int = 0
@export var player_id: String = "player2"  # Identificador único

# --- Nodos ---
@onready var sonido_aturdido: AudioStreamPlayer2D = $sonido_aturdido
@onready var sonido_flotando: AudioStreamPlayer2D = $sonido_flotando

@onready var bar: TextureProgressBar = $"../CanvasLayer/ProgressBar_alien_2"
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var bar_ability_2: ProgressBar = $"../CanvasLayer/ProgressBar_ability_2"
@onready var coin_label: Label = $"../CanvasLayer/cont monedas2"

# --- Movimiento ---
var speed := 220
var controls_inverted := false
var invert_duration := 2.0 
var invert_timer := 0.0
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

# --- Estado ---
var dead := false
var allow_input := true

# -- Mecánica de golpes
var _use_left := true
var _punch_lock := false
@onready var punch_right: Sprite2D = $Punch_right
@onready var punch_left: Sprite2D = $Punch_left

# --- Facing / bases de puños ---
var _facing := 1                   # 1=mirando a la derecha, -1=izquierda
var _base_left  := Vector2.ZERO    # posición base de Punch_left mirando a la derecha
var _base_right := Vector2.ZERO    # posición base de Punch_right mirando a la derecha

# ======================
#     PODER: ESPADA
# ======================
@export var espada_scene: PackedScene         # arrástrala en el inspector
@export var espada_duracion: float = 15.0     # por defecto 15 s

var _sword_instance: Node2D = null
var _sword_active := false
var _sword_timer: Timer

# ======================
#       SALTO (pseudo-3D)
# ======================
@export var jump_force: float = 220.0    # velocidad inicial (positivo)
@export var gravity: float = 600.0       # gravedad aplicada (positivo)
var z: float = 0.0                       # altura actual
var z_velocity: float = 0.0              # velocidad vertical (positiva = sube)
var is_jumping: bool = false

# ======================
#   FUNCIONES BÁSICAS
# ======================
func _ready() -> void:
	var alabarda = $alabarda
	var hitbox = alabarda.get_node("Hitbox")
	hitbox.monitoring = false  # 🔹 aseguramos que arranque desactivado

	coins = GameState.get_coins(player_id)
	GameState.set_coins(player_id, coins)
	if coin_label:
		coin_label.text = str(coins)
	else:
		push_error("⚠️ No se encontró el nodo Label de monedas en el árbol de nodos.")

	if bar_ability_2:
		bar_ability_2.min_value = 0
		bar_ability_2.max_value = 150
		bar_ability_2.value = bar_ability_2.min_value

	# Guardamos las posiciones base de los puños (para restaurar y calcular offsets)
	_base_left  = punch_left.position
	_base_right = punch_right.position
	_use_left = (randi() & 1) == 0

	if not is_connected("damage", Callable(self, "_on_damage")):
		connect("damage", Callable(self, "_on_damage"))

	animated_sprite.play("idle")
	if not is_in_group("players"):
		add_to_group("players")

	# Timer para revertir la espada
	_sword_timer = Timer.new()
	_sword_timer.one_shot = true
	add_child(_sword_timer)
	if not _sword_timer.is_connected("timeout", Callable(self, "_revert_sword")):
		_sword_timer.connect("timeout", Callable(self, "_revert_sword"))

	_set_facing(1)

# ----------------------
#   FACING / PUÑOS
# ----------------------
func _set_facing(sign_dir: int) -> void:
	if sign_dir == 0:
		return
	_facing = sign_dir

	# Flip visual del cuerpo
	animated_sprite.flip_h = (_facing < 0)

	# Flip visual de los puños (solo flip, posición la actualizaremos cada frame)
	punch_left.flip_h  = animated_sprite.flip_h
	punch_right.flip_h = animated_sprite.flip_h

	# Reubica puños a su lado correcto (usamos base X multiplicada por _facing; Y la dejamos para el salto)
	if not _punch_lock:
		punch_left.position  = Vector2(_base_left.x  * _facing, _base_left.y)
		punch_right.position = Vector2(_base_right.x * _facing, _base_right.y)

	# Re-ancle arma / espada si está activa
	_update_sword_transform()

func _punch_alternate()-> void:
	if _punch_lock:
		return
	_punch_lock = true
	if _use_left:
		var base_l = punch_left.position
		var dir_l = -1.0 if $Punch_left.flip_h else 1.0
		var t = create_tween()
		t.tween_property(punch_left, "position", base_l + Vector2(45.0 * dir_l, 0.0), 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_property(punch_left, "position", base_l, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		t.tween_callback(Callable(self, "_on_punch_done"))
	else:
		var base_r = punch_right.position
		var dir_r = -1.0 if $Punch_right.flip_h else 1.0
		var t_r = create_tween()
		t_r.tween_property(punch_right, "position", base_r + Vector2(45.0 * dir_r, 0.0), 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t_r.tween_property(punch_right, "position", base_r, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		t_r.tween_callback(Callable(self, "_on_punch_done"))
	_use_left = not _use_left

func _on_punch_done()-> void:
	_punch_lock = false

# ----------------------
#   FLOTAR
# ----------------------
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

# =====================
#   PROCESO PRINCIPAL
# =====================
func _physics_process(delta: float) -> void:
	if dead:
		velocity = Vector2.ZERO
		return
	if Input.is_action_just_pressed("area_veneno") and not selecting_poison:
		selecting_poison = true
		poison_preview = Node2D.new()
		var circle := ColorRect.new()
		circle.color = Color(0,1,0,0.3)  # verde transparente
		circle.size = Vector2(100,100)   # tamaño del área
		circle.position = -circle.size/2
		poison_preview.add_child(circle)
		get_tree().current_scene.add_child(poison_preview)
	if selecting_poison and poison_preview:
		poison_preview.global_position = get_global_mouse_position()

		# Colocar veneno con click izquierdo
		if Input.is_action_just_pressed("click_izquierdo"):  # define "click_izquierdo" en Input Map
			var poison_instance = poison_area_scene.instantiate()
			get_tree().current_scene.add_child(poison_instance)
			poison_instance.global_position = poison_preview.global_position

			poison_preview.queue_free()
			poison_preview = null
			selecting_poison = false

	# Input y movimiento
	var direction = Vector2.ZERO
	if allow_input:
		direction = Input.get_vector("left_player_2", "right_player_2", "up_player_2", "down_player_2")

	# Actualiza facing si hay input en X
	if abs(direction.x) > 0.01:
		_set_facing(sign(direction.x))

	# Si hay input de puño (fired_2)
	if Input.is_action_just_pressed("fired_2"):
		_punch_alternate()

	# Animaciones / estados
	match estado_actual:
		Estado.VENENO:
			if animated_sprite.animation != "envenenado":
				animated_sprite.play("envenenado")
			if abs(direction.x) > 0:
				animated_sprite.flip_h = direction.x < 0

		Estado.ATURDIDO:
			if not sonido_aturdido.playing:
				sonido_aturdido.play()
			direction = -direction
			if animated_sprite.animation != "aturdido":
				animated_sprite.play("aturdido")
			if abs(direction.x) > abs(direction.y):
				animated_sprite.flip_h = direction.x < 0

		Estado.NORMAL:
			if sonido_aturdido.playing:
				sonido_aturdido.stop()
			if direction == Vector2.ZERO and not is_jumping:
				animated_sprite.play("idle")
			else:
				if not is_jumping:
					if abs(direction.x) > abs(direction.y):
						animated_sprite.play("caminar")
						animated_sprite.flip_h = direction.x < 0
					elif direction.y < 0:
						animated_sprite.play("caminar_subir")
					else:
						animated_sprite.play("caminar_bajar")

	velocity = direction * speed

	# ====== SALTO ======
	# Solo permitir saltar si no estamos flotando y no ya saltando
	if allow_input and Input.is_action_just_pressed("jump_2") and not is_jumping and not floating:
		is_jumping = true
		z_velocity = jump_force

	# Física vertical del salto (pseudo-3D)
	if is_jumping:
		# gravity reduce z_velocity para que +vel -> sube, restamos gravity
		z_velocity -= gravity * delta
		z += z_velocity * delta

		# Si llegamos o pasamos el suelo
		if z <= 0.0:
			z = 0.0
			z_velocity = 0.0
			is_jumping = false

	# Movimiento (usa move_and_slide como antes)
	if not floating:
		move_and_slide()
	else:
		_handle_floating(delta)

	# ====== Aplicar "altura" visual al sprite y a los puños ======
	# AnimatedSprite se mueve visualmente hacia arriba cuando z > 0
	animated_sprite.position.y = -z

	# Reposicionamos puños cada frame para que sigan al jugador en X y suban/bajen con z
	var left_x = _base_left.x * _facing
	var right_x = _base_right.x * _facing
	punch_left.position = Vector2(left_x, _base_left.y - z)
	punch_right.position = Vector2(right_x, _base_right.y - z)

	# Si la espada está activa, moverla también visualmente
	_update_sword_transform()

# =====================
#   DAÑO RECIBIDO
# =====================
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
				estado_actual = Estado.VENENO
				$venenoTimer.start(0.2)
				animated_sprite.play("envenenado")

		"bala":
			if estado_actual == Estado.NORMAL:
				estado_actual = Estado.ATURDIDO
				$Timer.start(2)
				animated_sprite.play("aturdio")

		"bala_gravedad":
			floating = true
			invulnerable = true
			invul_timer = invul_duration

# ----------------------
#   COLISIONES SALIENTES
# ----------------------
func _on_damage_enemy_body_entered(body: Node2D) -> void:
	if body.is_in_group("gun_enemy") and not invulnerable and not dead:
		emit_signal("damage", 20.0, "bala")

# ----------------------
#   MUERTE / TIMERS
# ----------------------
func _die() -> void:
	dead = true
	allow_input = false
	floating = false
	invulnerable = false
	controls_inverted = false

	# Si hay espada activa, quítala
	_revert_sword()

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

	$"../CanvasLayer/Sprite2D2".self_modulate = Color(1, 0, 0, 1) 
	$"../CanvasLayer/Character2Profile".texture = preload("res://Assets/art/sprites/complements_sprites/muerto_big.png")
	emit_signal("muerte")

func _on_death_finished() -> void:
	if animated_sprite.animation == "death":
		animated_sprite.playing = false

func _on_timer_timeout() -> void:
	if estado_actual == Estado.ATURDIDO:
		estado_actual = Estado.NORMAL

func collect_coin(amount: int = 1) -> void:
	coins += amount
	if coin_label:
		coin_label.text = str(coins)
	GameState.set_coins(player_id, coins)

func _on_veneno_timer_timeout() -> void:
	if estado_actual == Estado.VENENO:
		estado_actual = Estado.NORMAL

func _on_area_2d_body_entered(body: Node2D) -> void:
	var dmg := 0.0
	if body.is_in_group("enemy_1") or body.is_in_group("enemy_2"):
		dmg = 30.0
	elif body.is_in_group("enemy_3") or body.is_in_group("enemy_4"):
		dmg = 10.0
	elif body.is_in_group("enemy_5"):
		dmg = 20.0
	elif body.is_in_group("boss"):
		dmg = 10.0
	if dmg > 0.0 and body.has_signal("damage"):
		body.emit_signal("damage", dmg)
		gain_ability_from_attack_2(dmg)

# ----------------------
#   PODER: ESPADA
# ----------------------
func activate_sword_for(seconds: float = -1.0) -> void:
	if dead:
		return
	if espada_scene == null:
		push_warning("[P2] No hay espada_scene asignada en el Inspector.")
		return
	if seconds <= 0.0:
		seconds = espada_duracion

	# Si ya está activa, sólo renueva tiempo
	if _sword_active and is_instance_valid(_sword_instance):
		_sword_timer.start(seconds)
		return

	# Instanciar y anclar
	_sword_instance = espada_scene.instantiate() as Node2D
	add_child(_sword_instance)
	_update_sword_transform()

	# (Opcional) ocultar puños mientras está la espada
	if has_node("Punch_left"):
		$Punch_left.visible = false
	if has_node("Punch_right"):
		$Punch_right.visible = false

	# Escuchar el daño de la espada para cargar la barra
	if _sword_instance.has_signal("dealt_damage"):
		if not _sword_instance.is_connected("dealt_damage", Callable(self, "_on_sword_dealt_damage")):
			_sword_instance.connect("dealt_damage", Callable(self, "_on_sword_dealt_damage"))

	_sword_active = true
	_sword_timer.start(seconds)

func _revert_sword() -> void:
	if is_instance_valid(_sword_instance):
		_sword_instance.queue_free()
		_sword_instance = null
	_sword_active = false

	# Rehabilita puños
	punch_left.visible  = true
	punch_right.visible = true

func _update_sword_transform() -> void:
	if not _sword_active or not is_instance_valid(_sword_instance):
		return
	# Anchor basado en base_right (como tenías antes) y aplicamos offset vertical por salto (z)
	var anchor := Vector2(abs(_base_right.x) * _facing, _base_right.y - z)
	_sword_instance.position = anchor
	_sword_instance.scale.x = abs(_sword_instance.scale.x) * float(_facing)

# ======================
#  CARGA DE HABILIDAD 2
# ======================
func gain_ability_from_attack_2(damage_dealt: float) -> void:
	if dead or bar_ability_2 == null:
		return
	var gain = max(0.0, damage_dealt)
	bar_ability_2.value = clamp(bar_ability_2.value + gain, bar_ability_2.min_value, bar_ability_2.max_value)
	if bar_ability_2.value >= bar_ability_2.max_value:
		_power()

func _power() -> void:
	if dead:
		return
	if bar_ability_2 and bar_ability_2.value >= bar_ability_2.max_value:
		bar_ability_2.value = bar_ability_2.min_value
		var alabarda = $alabarda
		var hitbox = alabarda.get_node("Hitbox")
		alabarda.visible = true
		alabarda.rotation_degrees = 0
		hitbox.monitoring = true  # activar hitbox

		var t = create_tween()

		# 1. Carga del golpe (wind-up)
		t.tween_property(alabarda, "rotation_degrees", -45.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		# 2. Swing fuerte
		t.tween_property(alabarda, "rotation_degrees", 120.0, 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

		# 3. Regresa
		t.tween_property(alabarda, "rotation_degrees", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		# 4. Termina
		t.tween_callback(Callable(self, "_end_power"))

func _end_power() -> void:
	var alabarda = $alabarda
	var hitbox = alabarda.get_node("Hitbox")
	alabarda.rotation_degrees = 0
	alabarda.hide()
	hitbox.monitoring = false

func _on_hitbox_area_entered(area: Area2D) -> void:
	var enemy = area.get_parent()
	if (enemy.is_in_group("enemy_1") 
		or enemy.is_in_group("enemy_2") 
		or enemy.is_in_group("enemy_3") 
		or enemy.is_in_group("enemy_4") 
		or enemy.is_in_group("enemy_5") 
		or enemy.is_in_group("boss")) and enemy.has_signal("damage"):
		enemy.emit_signal("damage", 20.0)  # daño fijo de la alabarda
		
