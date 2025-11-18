extends CharacterBody2D
# player 2
<<<<<<< HEAD
@onready var TimerGolpeUlti: Timer = Timer.new()
var _flotar_sound_played := false
var poison_charge: int = 0
var poison_max_charge: int = 10
var poison_ready: bool = false
var selecting_poison: bool = false
var poison_preview: Node2D = null

@onready var veneno_couldown: ProgressBar = $"../CanvasLayer/Veneno_p2"
@export var poison_area_scene: PackedScene
@export var poison_cursor_speed := 700.0
@export var poison_cooldown_duration := 20.0
var _poison_cooldown_remaining := 0.0
# --- Señales ---
signal damage(amount: float, source: String)
signal muerte  # Para notificar al GameManager
# ============================
# PODER: ÁREA DE VENENO




var poison_in_selection: bool = false

@onready var poison_timer: Timer = Timer.new()

# --- NUEVO: Variables de Cooldown para el Veneno ---

# ======================
#        DASH
# ======================
@export var dash_speed := 600.0      # Velocidad del dash
@export var dash_duration := 0.2     # Duración del dash (segundos)
@export var dash_cooldown := 0.6     # Tiempo antes de volver a usarlo

var _is_dashing := false
var _dash_timer := 0.0
var _dash_cooldown_timer := 0.0
var _dash_dir := Vector2.ZERO
# --- Variables ---
var coins: int = 0
@export var player_id: String = "player2"  # Identificador único

var ulti_active: bool = false
var ulti_ready := false # <-- NUEVA VARIABLE: para saber si el ulti está listo
@export var ulti_drain_rate := 30.0 # <-- NUEVA VARIABLE: velocidad de consumo

var punch_base_dmg := {
	"enemy_1": 30.0,
	"enemy_2": 30.0,
	"enemy_3": 10.0,
	"enemy_4": 10.0,
	"enemy_5": 20.0,
	"boss": 30.0
}

# --- Nodos ---
=======

# =========================
# Señales
# =========================
signal damage(amount: float, source: String)
signal muerte

# =========================
# Constantes / Utilidades
# =========================
const ENEMY_GROUPS := ["enemy_1","enemy_2","enemy_3","enemy_4","enemy_5","boss"]

# =========================
# Nodos
# =========================
@onready var TimerGolpeUlti: Timer = Timer.new()
@onready var veneno_couldown: ProgressBar = $"../CanvasLayer/Veneno_p2"
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
@onready var sonido_aturdido: AudioStreamPlayer2D = $sonido_aturdido
@onready var sonido_flotando: AudioStreamPlayer2D = $sonido_flotando
@onready var sonido_ulti: AudioStreamPlayer2D = $sonido_ulti
@onready var bar: TextureProgressBar = $"../CanvasLayer/ProgressBar_alien_2"
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
<<<<<<< HEAD
@onready var bar_ability_2: ProgressBar = $"../CanvasLayer/ProgressBar_ability_2"
@onready var coin_label: Label = $"../CanvasLayer/cont monedas2"

# --- Movimiento ---
var speed := 220
var controls_inverted := false
var invert_duration := 2.0 
var invert_timer := 0.0
=======
@onready var bar_ability_2: ProgressBar = $"../../CanvasLayer/ProgressBar_ability_2"
@onready var coin_label: Label = $"../../CanvasLayer/cont monedas2"
@onready var punch_right: Sprite2D = $Punch_right
@onready var punch_left: Sprite2D = $Punch_left
@onready var punchs: AudioStreamPlayer2D = $punchs

# =========================
# Variables estado / gameplay
# =========================
var _flotar_sound_played := false

# Veneno
@export var poison_area_scene: PackedScene
@export var poison_cursor_speed := 700.0
@export var poison_cooldown_duration := 20.0
var poison_charge: int = 0
var poison_max_charge: int = 10
var poison_ready: bool = false
var selecting_poison: bool = false
var poison_preview: Node2D = null
var poison_in_selection: bool = false
var _poison_cooldown_remaining := 0.0
@onready var poison_timer: Timer = Timer.new()

# Dash
@export var dash_speed := 600.0
@export var dash_duration := 0.2
@export var dash_cooldown := 0.6
var _is_dashing := false
var _dash_timer := 0.0
var _dash_cooldown_timer := 0.0
var _dash_dir := Vector2.ZERO

# Monedas / vida / UI
var coins: int = 0
@export var player_id: String = "player2"

# Ulti
var ulti_active: bool = false
var ulti_ready := false
@export var ulti_drain_rate := 30.0

# Daño de puños
var punch_base_dmg := {
	"enemy_1": 30.0, "enemy_2": 30.0, "enemy_3": 10.0,
	"enemy_4": 10.0, "enemy_5": 20.0, "boss": 30.0
}

# Movimiento / estados
var speed := 220
var controls_inverted := false
var invert_duration := 2.0
var invert_timer := 0.0

>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
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

<<<<<<< HEAD
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







@onready var punchs: AudioStreamPlayer2D = $punchs
var _punch_variations := [0.5, 1.0, 1.5]
# ======================
#   FUNCIONES BÁSICAS
# ======================
func _ready() -> void:
		# Configurar ProgressBar
=======
var dead := false
var allow_input := true

# Puños
var _use_left := true
var _punch_lock := false
var _facing := 1
var _base_left  := Vector2.ZERO
var _base_right := Vector2.ZERO
var _punch_variations := [0.5, 1.0, 1.5]

# ======================
# Ready
# ======================
func _ready() -> void:
	# Barra de veneno
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	veneno_couldown.min_value = 1
	veneno_couldown.max_value = poison_max_charge
	veneno_couldown.value = 0

<<<<<<< HEAD
	# Configurar timer de carga
	poison_timer.wait_time = 1.0  # cada segundo
	poison_timer.one_shot = false
	poison_timer.timeout.connect(_on_poison_timer_timeout)
	add_child(poison_timer)
	poison_timer.start()
	randomize()
	# ... lo que ya tienes ...
	_disable_stream_loop(sonido_flotando)
	# Timer de golpes de ulti (constante, repetitivo)
	TimerGolpeUlti.wait_time = 0.5   # intervalo entre golpes
=======
	# Carga automática de veneno
	poison_timer.wait_time = 1.0
	poison_timer.one_shot = false
	poison_timer.connect("timeout", Callable(self, "_on_poison_timer_timeout"))
	add_child(poison_timer)
	poison_timer.start()

	randomize()
	_disable_stream_loop(sonido_flotando)

	# Timer de ulti-golpes
	TimerGolpeUlti.wait_time = 0.5
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	TimerGolpeUlti.one_shot = false
	add_child(TimerGolpeUlti)
	if not TimerGolpeUlti.is_connected("timeout", Callable(self, "_ulti_punch")):
		TimerGolpeUlti.connect("timeout", Callable(self, "_ulti_punch"))

<<<<<<< HEAD
	var alabarda = $alabarda
	var hitbox = alabarda.get_node("Hitbox")
	hitbox.monitoring = false  # 🔹 aseguramos que arranque desactivado

=======
	# Alabarda: arrancar desactivada
	var alabarda := $alabarda
	var hitbox := alabarda.get_node("Hitbox")
	hitbox.monitoring = false

	# Monedas
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	coins = GameState.get_coins(player_id)
	GameState.set_coins(player_id, coins)
	if coin_label:
		coin_label.text = str(coins)
<<<<<<< HEAD
	else:
		push_error("⚠️ No se encontró el nodo Label de monedas en el árbol de nodos.")
	# --- Recuperar vida ---
	var vida_guardada = GameState.get_vida(player_id)

	if vida_guardada <= 0:
		# 🔹 Si estaba en 0 o menos, darle 30 de vida
		bar.value = bar.max_value
		GameState.set_vida(player_id, bar.value)
	else:
		bar.value = vida_guardada
=======

	# Vida
	var vida_guardada = GameState.get_vida(player_id)
	if vida_guardada <= 0:
		bar.value = bar.max_value
	else:
		bar.value = vida_guardada
	GameState.set_vida(player_id, bar.value)

	# Barra habilidad 2
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	if bar_ability_2:
		bar_ability_2.min_value = 0
		bar_ability_2.max_value = 150
		bar_ability_2.value = bar_ability_2.min_value

<<<<<<< HEAD
	# Guardamos las posiciones base de los puños (para restaurar y calcular offsets)
=======
	# Puños bases
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	_base_left  = punch_left.position
	_base_right = punch_right.position
	_use_left = (randi() & 1) == 0

<<<<<<< HEAD
=======
	# Señales
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	if not is_connected("damage", Callable(self, "_on_damage")):
		connect("damage", Callable(self, "_on_damage"))

	animated_sprite.play("idle")
	if not is_in_group("players"):
		add_to_group("players")

<<<<<<< HEAD
	# Timer para revertir la espada
=======
	# Timer espada
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	_sword_timer = Timer.new()
	_sword_timer.one_shot = true
	add_child(_sword_timer)
	if not _sword_timer.is_connected("timeout", Callable(self, "_revert_sword")):
		_sword_timer.connect("timeout", Callable(self, "_revert_sword"))

	_set_facing(1)

<<<<<<< HEAD
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
=======
# ======================
# Helpers genéricos
# ======================
func _set_facing(sign_dir: int) -> void:
	if sign_dir == 0: return
	_facing = sign_dir
	animated_sprite.flip_h = (_facing < 0)
	punch_left.flip_h  = animated_sprite.flip_h
	punch_right.flip_h = animated_sprite.flip_h
	if not _punch_lock:
		punch_left.position  = Vector2(_base_left.x  * _facing, _base_left.y)
		punch_right.position = Vector2(_base_right.x * _facing, _base_right.y)
	_update_sword_transform()

func _set_punches_visible(v: bool) -> void:
	punch_left.visible = v
	punch_right.visible = v

func _play_anim_safe(name: String) -> void:
	if animated_sprite.animation != name:
		animated_sprite.play(name)

func _is_enemy(node: Node) -> bool:
	if node == null: return false
	for g in ENEMY_GROUPS:
		if node.is_in_group(g): return true
	return false

func _loop_audio(player: AudioStreamPlayer2D, should_loop: bool) -> void:
	if player == null: return
	var s = player.stream
	if s == null: return
	var s_copy = s.duplicate(true)
	if "loop_mode" in s_copy:
		if "loop_mode" in s_copy:
			if should_loop:
				s_copy.loop_mode = 2   # LOOP
			else:
				s_copy.loop_mode = 0   # NO LOOP
	elif "loop" in s_copy:
		s_copy.loop = should_loop
	elif "loop_enabled" in s_copy:
		s_copy.loop_enabled = should_loop
	player.stream = s_copy

func _update_poison_cooldown(delta: float) -> void:
	if _poison_cooldown_remaining <= 0.0:
		return
	_poison_cooldown_remaining = max(0.0, _poison_cooldown_remaining - delta)
	veneno_couldown.value = _poison_cooldown_remaining
	if _poison_cooldown_remaining <= 0.0:
		poison_charge = 0
		veneno_couldown.max_value = poison_max_charge
		veneno_couldown.value = 0
# ======================
# Puños
# ======================
func _punch_alternate() -> void:
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	if _punch_lock:
		return
	_punch_lock = true
	_play_punch_sfx()
	if _use_left:
<<<<<<< HEAD
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
=======
		var base_l := punch_left.position
		var dir_l := 1.0
		if punch_left.flip_h:
			dir_l = -1.0
		var t := create_tween()
		t.tween_property(punch_left, "position", base_l + Vector2(105.0 * dir_l, 0.0), 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_property(punch_left, "position", base_l, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		t.tween_callback(Callable(self, "_on_punch_done"))
	else:
		var base_r := punch_right.position
		var dir_r := 1.0
		if punch_right.flip_h:
			dir_r = -1.0
		var t_r := create_tween()
		t_r.tween_property(punch_right, "position", base_r + Vector2(75.0 * dir_r, 0.0), 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t_r.tween_property(punch_right, "position", base_r, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		t_r.tween_callback(Callable(self, "_on_punch_done"))
	_use_left = not _use_left
func _on_punch_done() -> void:
	_punch_lock = false
func _play_punch_sfx() -> void:
	if punchs:
		var p = _punch_variations[randi() % _punch_variations.size()]
		punchs.pitch_scale = p
		punchs.play()
# ======================
# Flotar
# ======================
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
func _handle_floating(delta: float) -> void:
	if floating:
		if not _flotar_sound_played:
			sonido_flotando.play()
			_flotar_sound_played = true
	else:
		_flotar_sound_played = false
		if sonido_flotando.playing:
			sonido_flotando.stop()
<<<<<<< HEAD


	var target_y
	var current_lerp_speed
	var current_rotation_speed

=======
	var target_y
	var current_lerp_speed
	var current_rotation_speed
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
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
<<<<<<< HEAD

	global_position.y = lerp(global_position.y, target_y, current_lerp_speed * delta)
	rotation += current_rotation_speed * delta

	set_collision_layer(0)
	set_collision_mask(0)

	invul_timer -= delta

=======
	global_position.y = lerp(global_position.y, target_y, current_lerp_speed * delta)
	rotation += current_rotation_speed * delta
	set_collision_layer(0)
	set_collision_mask(0)
	invul_timer -= delta
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	if invul_timer <= 0.0 and abs(global_position.y - float_start_y) < 1.0:
		floating = false
		invulnerable = false
		rotation = 0.0
		global_position.y = float_start_y
		set_collision_layer(1)
		set_collision_mask(1)
<<<<<<< HEAD

# =====================
#   PROCESO PRINCIPAL
# =====================
func _physics_process(delta: float) -> void:
	# si está listo pero aún no seleccionando → activar preludio
	# Si está en cooldown → bajar la barra
	if _poison_cooldown_remaining > 0:
		_poison_cooldown_remaining = max(0.0, _poison_cooldown_remaining - delta)
		veneno_couldown.value = _poison_cooldown_remaining

		# Cuando termina el cooldown → volver a cargar
		if _poison_cooldown_remaining <= 0:
			poison_charge = 0
			veneno_couldown.max_value = poison_max_charge
			veneno_couldown.value = 0

=======
# ======================
# Physics process
# ======================
func _physics_process(delta: float) -> void:
	_update_poison_cooldown(delta)
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	if dead:
		velocity = Vector2.ZERO
		return
	if ulti_active:
<<<<<<< HEAD
		# Consumir la barra de habilidad con el tiempo
		bar_ability_2.value -= ulti_drain_rate * delta
		
		# Regenerar vida mientras el ulti está activo
		if bar:
			var regen = 20 * delta
			bar.value = min(bar.value + regen, bar.max_value)
			GameState.set_vida(player_id, bar.value) # 🔹 Guardamos la vida actual

		# Si la barra se agota, desactivar el ulti
		if bar_ability_2.value <= 0:
			_end_ulti()

=======
		bar_ability_2.value -= ulti_drain_rate * delta
		if bar:
			var regen = 20 * delta
			bar.value = min(bar.value + regen, bar.max_value)
			GameState.set_vida(player_id, bar.value)
		if bar_ability_2.value <= 0:
			_end_ulti()
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	if _is_dashing:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_end_dash()
		else:
			velocity = _dash_dir * dash_speed
			move_and_slide()
		return
<<<<<<< HEAD

	# Cooldown
	if _dash_cooldown_timer > 0.0:
		_dash_cooldown_timer -= delta


	

	# --- LÓGICA DE VENENO MEJORADA ---
	# 1. Activar o cancelar el modo de apuntado
	#if Input.is_action_just_pressed("toggle_poison_aim_p2"):
	#	if selecting_poison:
		#	_cancel_poison_selection() # Si ya estamos apuntando, cancelamos.
	#	elif not floating:
		#	_enter_poison_selection() # Si no, entramos en el modo de apuntado.

	# 2. Lógica mientras estamos apuntando
	if selecting_poison and poison_preview:
		# Mover el cursor (con joystick o ratón)
		var joy_cursor_vector = Input.get_vector("cursor_left_p2", "cursor_right_p2", "cursor_up_p2", "cursor_down_p2")
=======
	if _dash_cooldown_timer > 0.0:
		_dash_cooldown_timer -= delta
	# Modo de apuntado del veneno
	if selecting_poison and is_instance_valid(poison_preview):
		var joy_cursor_vector := Input.get_vector("cursor_left_p2", "cursor_right_p2", "cursor_up_p2", "cursor_down_p2")
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
		if joy_cursor_vector.length() > 0.1:
			poison_preview.global_position += joy_cursor_vector * poison_cursor_speed * delta
		else:
			poison_preview.global_position = get_global_mouse_position()
<<<<<<< HEAD

		# Confirmar y colocar el veneno (con A/X o click)
		if (Input.is_action_just_pressed("veneno_activo") or Input.is_action_just_pressed("confirm_action_p2")):
=======
		if Input.is_action_just_pressed("veneno_activo") or Input.is_action_just_pressed("confirm_action_p2"):
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
			_activate_poison()
			_cancel_poison_selection()
			poison_ready = false
			poison_charge = 0
			veneno_couldown.value = 0
			poison_in_selection = false
<<<<<<< HEAD
			veneno_couldown.value = 0


	# --- Dirección
	var direction = Vector2.ZERO
=======
	# Movimiento e inputs
	var direction := Vector2.ZERO
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	if allow_input:
		direction = Input.get_vector("left_player_2", "right_player_2", "up_player_2", "down_player_2")
	if Input.is_action_just_pressed("dash2") and not _is_dashing and _dash_cooldown_timer <= 0.0 and not floating:
		if direction != Vector2.ZERO:
			_start_dash(direction)
		else:
<<<<<<< HEAD
			# si no hay dirección, usa la última facing
			_start_dash(Vector2(_facing, 0))
	if Input.is_action_just_pressed("jump_2") and not floating:
		_power()
		
	if Input.is_action_just_pressed("ulti_player_2") and ulti_ready and not ulti_active:
		_start_ulti()

	# --- Actualizar facing si hay input
	if abs(direction.x) > 0.01:
		_set_facing(sign(direction.x))

	# --- Input de puño
	if Input.is_action_just_pressed("fired_2") and not selecting_poison and not floating:
		_punch_alternate()

	# --- Animaciones / estados
	if selecting_poison:
		# 🔹 Permitir que animaciones de daño interrumpan "lanzar"
		if estado_actual == Estado.ATURDIDO:
			if animated_sprite.animation != "aturdido":
				animated_sprite.play("aturdido")
		elif estado_actual == Estado.VENENO:
			if animated_sprite.animation != "envenenado":
				animated_sprite.play("envenenado")
		# Si no hay estados que interrumpan → mantener lanzar
		elif animated_sprite.animation != "lanzar":
			animated_sprite.play("lanzar")
	else:
		match estado_actual:
			Estado.VENENO:
				if animated_sprite.animation != "envenenado":
					animated_sprite.play("envenenado")
				if abs(direction.x) > 0:
					animated_sprite.flip_h = direction.x < 0

=======
			_start_dash(Vector2(_facing, 0))
	if Input.is_action_just_pressed("jump_2") and not floating:
		_power()
	if Input.is_action_just_pressed("ulti_player_2") and ulti_ready and not ulti_active:
		_start_ulti()
	if abs(direction.x) > 0.01:
		_set_facing(sign(direction.x))
	if Input.is_action_just_pressed("fired_2") and not selecting_poison and not floating:
		_punch_alternate()
	# Animaciones por estado
	if selecting_poison:
		match estado_actual:
			Estado.ATURDIDO:
				_play_anim_safe("aturdido")
			Estado.VENENO:
				_play_anim_safe("envenenado")
			_:
				_play_anim_safe("lanzar")
	else:
		match estado_actual:
			Estado.VENENO:
				_play_anim_safe("envenenado")
				if abs(direction.x) > 0:
					animated_sprite.flip_h = direction.x < 0
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
			Estado.ATURDIDO:
				if not sonido_aturdido.playing:
					sonido_aturdido.play()
				direction = -direction
<<<<<<< HEAD
				if animated_sprite.animation != "aturdido":
					animated_sprite.play("aturdido")
				if abs(direction.x) > abs(direction.y):
					animated_sprite.flip_h = direction.x < 0

=======
				_play_anim_safe("aturdido")
				if abs(direction.x) > abs(direction.y):
					animated_sprite.flip_h = direction.x < 0
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
			Estado.NORMAL:
				if sonido_aturdido.playing:
					sonido_aturdido.stop()
				if ulti_active:
<<<<<<< HEAD
					if animated_sprite.animation != "ulti_pose":
						animated_sprite.play("ulti_pose")
				else:
					if direction == Vector2.ZERO:
						animated_sprite.play("idle")
					else:
						if abs(direction.x) > abs(direction.y):
							animated_sprite.play("caminar")
							animated_sprite.flip_h = direction.x < 0
						elif direction.y < 0:
							animated_sprite.play("caminar_subir")

	# --- Movimiento
=======
					_play_anim_safe("ulti_pose")
				else:
					if direction == Vector2.ZERO:
						_play_anim_safe("idle")
					else:
						if abs(direction.x) > abs(direction.y):
							_play_anim_safe("caminar")
							animated_sprite.flip_h = direction.x < 0
						elif direction.y < 0:
							_play_anim_safe("caminar_subir")

	# Aplicar movimiento
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	if not floating:
		velocity = direction * speed
		move_and_slide()
		if sonido_flotando.playing:
			sonido_flotando.stop()
	else:
		_handle_floating(delta)

<<<<<<< HEAD


func push_temp(offset: Vector2) -> void:
	global_position += offset


# =====================
#   DAÑO RECIBIDO
# =====================
# =====================
#   DAÑO RECIBIDO
# =====================
func _on_damage(amount: float, source: String = "desconocido") -> void:
	if dead:
		return

	if bar:
		bar.value = clamp(bar.value - amount, bar.min_value, bar.max_value)
		GameState.set_vida(player_id, bar.value) # 🔹 Guardamos la vida actual
=======
# ======================
# Utilidad de empuje
# ======================
func push_temp(offset: Vector2) -> void:
	global_position += offset

# ======================
# Daño recibido
# ======================
func _on_damage(amount: float, source: String = "desconocido") -> void:
	if dead: return

	if bar:
		bar.value = clamp(bar.value - amount, bar.min_value, bar.max_value)
		GameState.set_vida(player_id, bar.value)
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
		if bar.value <= bar.min_value:
			_die()
			return

	match source:
		"veneno":
			if estado_actual == Estado.NORMAL:
				estado_actual = Estado.VENENO
				$venenoTimer.start(0.2)
<<<<<<< HEAD
				animated_sprite.play("envenenado")

		"bala":
			if estado_actual == Estado.NORMAL and not ulti_active:  # 🔹 inmune al aturdimiento en ulti
				estado_actual = Estado.ATURDIDO
				$Timer.start(2)
				animated_sprite.play("aturdido")

		"bala_gravedad":
			if not ulti_active:  # 🔹 aquí agregamos la restricción
				_flotar_sound_played = false        # permitir que se vuelva a reproducir
				if sonido_flotando.playing:
					sonido_flotando.stop()         # corta cualquier reproducción anterior
=======
				_play_anim_safe("envenenado")
		"bala":
			if estado_actual == Estado.NORMAL and not ulti_active:
				estado_actual = Estado.ATURDIDO
				$Timer.start(2)
				_play_anim_safe("aturdido")
		"bala_gravedad":
			if not ulti_active:
				_flotar_sound_played = false
				if sonido_flotando.playing:
					sonido_flotando.stop()
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
					if sonido_flotando.has_method("seek"):
						sonido_flotando.seek(0.0)
				floating = true
				invulnerable = true
				invul_timer = invul_duration

<<<<<<< HEAD




# ----------------------
#   COLISIONES SALIENTES
# ----------------------
=======
# ======================
# Colisiones salientes
# ======================
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
func _on_damage_enemy_body_entered(body: Node2D) -> void:
	if body.is_in_group("gun_enemy") and not invulnerable and not dead:
		emit_signal("damage", 20.0, "bala")

<<<<<<< HEAD
=======
# ======================
# Muerte
# ======================
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
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
	TimerGolpeUlti.stop()
	$Timer.stop()
	$venenoTimer.stop()
	_revert_sword()

	if is_in_group("player_2"):
		remove_from_group("player_2")
	if is_in_group("players"):
		remove_from_group("players")

<<<<<<< HEAD
	if animated_sprite:
		animated_sprite.play("death")
		# La animación de muerte se queda hasta el final
		if not animated_sprite.is_connected("animation_finished", Callable(self, "_on_death_finished")):
			animated_sprite.connect("animation_finished", Callable(self, "_on_death_finished"), CONNECT_ONE_SHOT)

	$"../CanvasLayer/Sprite2D2".self_modulate = Color(1, 0, 0, 1) 
=======
	_play_anim_safe("death")
	if not animated_sprite.is_connected("animation_finished", Callable(self, "_on_death_finished")):
		animated_sprite.connect("animation_finished", Callable(self, "_on_death_finished"), CONNECT_ONE_SHOT)

	$"../CanvasLayer/Sprite2D2".self_modulate = Color(1, 0, 0, 1)
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	$"../CanvasLayer/Character2Profile".texture = preload("res://Assets/art/sprites/complements_sprites/muerto_big.png")
	emit_signal("muerte")

func _on_death_finished() -> void:
	if animated_sprite.animation == "death":
		animated_sprite.playing = false

func _on_timer_timeout() -> void:
	if estado_actual == Estado.ATURDIDO:
		estado_actual = Estado.NORMAL

<<<<<<< HEAD
# ====================== FUNCIÓN PARA COLECCIONAR MONEDAS =======================
=======
# ======================
# Monedas
# ======================
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
func collect_coin(amount: int = 1) -> void:
	coins += amount
	if coin_label:
		coin_label.text = str(coins)
	GameState.set_coins(player_id, coins)
	if coins >= 20:
		bar.value = clamp(bar.value + 200, bar.min_value, bar.max_value)
<<<<<<< HEAD
		GameState.set_vida(player_id, bar.value) # 🔹 Guardamos la vida actual
		#_show_shop()
=======
		GameState.set_vida(player_id, bar.value)
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
		coins = 0
		if coin_label:
			coin_label.text = str(coins)
			GameState.set_coins(player_id, coins)

func _on_veneno_timer_timeout() -> void:
	if estado_actual == Estado.VENENO:
		estado_actual = Estado.NORMAL

<<<<<<< HEAD
func _on_area_2d_body_entered(body: Node2D) -> void:
	var dmg := 0.0

	# ✅ Solo aplica daño si el jugador golpeó (fired_2) o si está en ulti
	if not ulti_active and not Input.is_action_pressed("fired_2"):
		return

	if body.is_in_group("enemy_1"):
		dmg = punch_base_dmg["enemy_1"]
	elif body.is_in_group("enemy_2"):
		dmg = punch_base_dmg["enemy_2"]
	elif body.is_in_group("enemy_3"):
		dmg = punch_base_dmg["enemy_3"]
	elif body.is_in_group("enemy_4"):
		dmg = punch_base_dmg["enemy_4"]
	elif body.is_in_group("enemy_5"):
		dmg = punch_base_dmg["enemy_5"]
	elif body.is_in_group("boss"):
		dmg = punch_base_dmg["boss"]

	# 🔹 Duplica daño si ulti está activa
=======
# ======================
# Área de puños / daño a enemigos
# ======================
func _on_area_2d_body_entered(body: Node2D) -> void:
	# Solo aplica daño si está golpeando o en ulti
	if not ulti_active and not Input.is_action_pressed("fired_2"):
		return

	if not _is_enemy(body): return

	var dmg := 0.0
	for k in punch_base_dmg.keys():
		if body.is_in_group(k):
			dmg = float(punch_base_dmg[k])
			break

>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	if ulti_active:
		dmg *= 2.0

	if dmg > 0.0 and body.has_signal("damage"):
<<<<<<< HEAD
		var modo: String
		if ulti_active:
			modo = "ULTI"
		else:
			modo = "NORMAL"
		body.emit_signal("damage", dmg)
		gain_ability_from_attack_2(dmg)


func _ulti_punch() -> void:
	if not ulti_active:
		return
	_play_punch_sfx()
	# Simula un golpe alternado visual
	_punch_alternate()

	# Buscar enemigos en rango (Area2D de puños)
	var area = $Area2D
	if area:
		for body in area.get_overlapping_bodies():
			if body.is_in_group("enemy_1") or body.is_in_group("enemy_2") \
			or body.is_in_group("enemy_3") or body.is_in_group("enemy_4") \
			or body.is_in_group("enemy_5") or body.is_in_group("boss"):
				if body.has_signal("damage"):
					body.emit_signal("damage", 50.0)



# ----------------------
#   PODER: ESPADA
# ----------------------
=======
		body.emit_signal("damage", dmg)
		gain_ability_from_attack_2(dmg)

# ======================
# Ulti auto-golpe
# ======================
func _ulti_punch() -> void:
	if not ulti_active: return
	_play_punch_sfx()
	_punch_alternate()

	var area := $Area2D
	if area:
		for body in area.get_overlapping_bodies():
			if _is_enemy(body) and body.has_signal("damage"):
				body.emit_signal("damage", 50.0)

# ======================
# Espada
# ======================
@export var espada_scene: PackedScene
@export var espada_duracion: float = 15.0
var _sword_instance: Node2D = null
var _sword_active := false
var _sword_timer: Timer

>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
func activate_sword_for(seconds: float = -1.0) -> void:
	if dead:
		velocity = Vector2.ZERO
		return
	if espada_scene == null:
		push_warning("[P2] No hay espada_scene asignada en el Inspector.")
		return
	if seconds <= 0.0:
		seconds = espada_duracion

<<<<<<< HEAD
	# Si ya está activa, sólo renueva tiempo
=======
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	if _sword_active and is_instance_valid(_sword_instance):
		_sword_timer.start(seconds)
		return

<<<<<<< HEAD
	# Instanciar y anclar
=======
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	_sword_instance = espada_scene.instantiate() as Node2D
	add_child(_sword_instance)
	_update_sword_transform()

<<<<<<< HEAD
	# (Opcional) ocultar puños mientras está la espada
	if has_node("Punch_left"):
		$Punch_left.visible = false
	if has_node("Punch_right"):
		$Punch_right.visible = false

	# Escuchar el daño de la espada para cargar la barra
=======
	_set_punches_visible(false)

>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
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
<<<<<<< HEAD

	# Rehabilita puños
	punch_left.visible  = true
	punch_right.visible = true
=======
	_set_punches_visible(true)
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771

func _update_sword_transform() -> void:
	if not _sword_active or not is_instance_valid(_sword_instance):
		return
<<<<<<< HEAD
	# Anchor basado en base_right (sin eje z)
=======
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	var anchor := Vector2(abs(_base_right.x) * _facing, _base_right.y)
	_sword_instance.position = anchor
	_sword_instance.scale.x = abs(_sword_instance.scale.x) * float(_facing)

<<<<<<< HEAD

# ======================
#  CARGA DE HABILIDAD 2
# ======================
# Reemplaza tu función actual con esta
func gain_ability_from_attack_2(damage_dealt: float) -> void:
	if dead or bar_ability_2 == null or ulti_active:
		return

	# 1. Solo cargamos la barra si el ulti no está ya listo
	if not ulti_ready:
		var gain = max(0.0, damage_dealt)
		bar_ability_2.value = clamp(bar_ability_2.value + gain, bar_ability_2.min_value, bar_ability_2.max_value)
		
		# 2. Si con esa carga se llenó, lo marcamos como listo
		if bar_ability_2.value >= bar_ability_2.max_value:
			ulti_ready = true
			# 3. YA NO llamamos a _start_ulti() aquí


=======
# ======================
# Habilidad 2 (carga)
# ======================
func gain_ability_from_attack_2(damage_dealt: float) -> void:
	if dead or bar_ability_2 == null or ulti_active:
		return
	if not ulti_ready:
		var gain = max(0.0, damage_dealt)
		bar_ability_2.value = clamp(bar_ability_2.value + gain, bar_ability_2.min_value, bar_ability_2.max_value)
		if bar_ability_2.value >= bar_ability_2.max_value:
			ulti_ready = true

# ======================
# Poder (alabarda)
# ======================
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
func _power() -> void:
	if dead:
		velocity = Vector2.ZERO
		return
<<<<<<< HEAD

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

func _start_ulti() -> void:
	if dead:
		return
	
	# 1. "Gastamos" la carga del ulti
	ulti_ready = false

	# 2. YA NO reiniciamos la barra de habilidad aquí. La dejamos llena.
	# if bar_ability_2:
	#	 bar_ability_2.value = bar_ability_2.min_value

=======
	var alabarda := $alabarda
	var hitbox := alabarda.get_node("Hitbox")
	alabarda.visible = true
	alabarda.rotation_degrees = 0
	hitbox.monitoring = true
	var t := create_tween()
	t.tween_property(alabarda, "rotation_degrees", -45.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(alabarda, "rotation_degrees", 120.0, 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	t.tween_property(alabarda, "rotation_degrees", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_callback(Callable(self, "_end_power"))
func _end_power() -> void:
	var alabarda := $alabarda
	var hitbox := alabarda.get_node("Hitbox")
	alabarda.rotation_degrees = 0
	alabarda.hide()
	hitbox.monitoring = false
func _on_hitbox_area_entered(area: Area2D) -> void:
	var enemy := area.get_parent()
	if _is_enemy(enemy) and enemy.has_signal("damage"):
		enemy.emit_signal("damage", 20.0)
# ======================
# Ulti on/off
# ======================
func _start_ulti() -> void:
	if dead: return
	ulti_ready = false
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	if estado_actual == Estado.ATURDIDO:
		estado_actual = Estado.NORMAL
		if not $Timer.is_stopped():
			$Timer.stop()
<<<<<<< HEAD

	ulti_active = true
	animated_sprite.play("ulti_pose")
	punch_left.visible = false
	punch_right.visible = false

	# 🔊 reproducir sonido de ulti en loop
	if sonido_ulti:
		var s = sonido_ulti.stream
		if s and ( "loop_mode" in s or "loop" in s or "loop_enabled" in s ):
			var s_copy = s.duplicate(true)
			if "loop_mode" in s_copy:
				s_copy.loop_mode = 2  # 2 = LOOP
			elif "loop" in s_copy:
				s_copy.loop = true
			elif "loop_enabled" in s_copy:
				s_copy.loop_enabled = true
			sonido_ulti.stream = s_copy
		sonido_ulti.stop()
		sonido_ulti.play()


func _end_ulti() -> void:
	ulti_active = false
	punch_left.visible = true
	punch_right.visible = true
	animated_sprite.play("idle")

	# 🔊 detener sonido de ulti
	if sonido_ulti and sonido_ulti.playing:
		sonido_ulti.stop()

	TimerGolpeUlti.stop()

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
		
func _process(delta: float) -> void:
	if ulti_active and bar:
		var regen = 20 * delta  # Ajusta la velocidad de regeneración
		bar.value = min(bar.value + regen, bar.max_value)
		GameState.set_vida(player_id, bar.value) # 🔹 Guardamos la vida actual

func _disable_stream_loop(player: AudioStreamPlayer2D) -> void:
	if player == null:
		return
	var s = player.stream
	if s == null:
		return
=======
	ulti_active = true
	_play_anim_safe("ulti_pose")
	_set_punches_visible(false)
	_loop_audio(sonido_ulti, true)
	sonido_ulti.stop()
	sonido_ulti.play()
func _end_ulti() -> void:
	ulti_active = false
	_set_punches_visible(true)
	_play_anim_safe("idle")
	if sonido_ulti and sonido_ulti.playing:
		sonido_ulti.stop()
	TimerGolpeUlti.stop()
# ======================
# Veneno (preview/colocación)
# ======================
func _enter_poison_selection() -> void:
	if dead or not allow_input or floating:
		return
	selecting_poison = true
	poison_preview = Node2D.new()
	_play_anim_safe("lanzar")
	_set_punches_visible(false)
	var sprite := Sprite2D.new()
	sprite.texture = preload("res://Assets/art/sprites/Particulas/botella2.png")
	sprite.scale = Vector2(1.5, 1.5)
	sprite.centered = true
	poison_preview.add_child(sprite)
	get_tree().current_scene.add_child(poison_preview)
	poison_preview.global_position = self.global_position + Vector2(60 * _facing, -30)
func _cancel_poison_selection() -> void:
	if is_instance_valid(poison_preview):
		poison_preview.queue_free()
	poison_preview = null
	selecting_poison = false
	_set_punches_visible(true)
	if animated_sprite.animation == "lanzar":
		_play_anim_safe("idle")
func _activate_poison() -> void:
	if poison_area_scene == null or poison_preview == null:
		return
	var poison_instance = poison_area_scene.instantiate()
	get_tree().current_scene.add_child(poison_instance)
	poison_instance.global_position = poison_preview.global_position
	_cancel_poison_selection()
func _place_poison_area():
	var poison_instance = poison_area_scene.instantiate()
	get_tree().current_scene.add_child(poison_instance)
	poison_instance.global_position = poison_preview.global_position
	_cancel_poison_selection()
	poison_ready = false
	poison_charge = 0
	_poison_cooldown_remaining = poison_cooldown_duration
	veneno_couldown.max_value = poison_cooldown_duration
	veneno_couldown.value = poison_cooldown_duration
func _on_poison_timer_timeout():
	if _poison_cooldown_remaining > 0 or poison_ready:
		return
	poison_charge = clamp(poison_charge + 1, 0, poison_max_charge)
	veneno_couldown.max_value = poison_max_charge
	veneno_couldown.value = poison_charge
	if poison_charge >= poison_max_charge:
		poison_ready = true
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("area_veneno") and poison_ready:
		if not poison_in_selection:
			_enter_poison_selection()
			poison_in_selection = true
		else:
			_activate_poison()
			_cancel_poison_selection()
			poison_charge = 0
			veneno_couldown.value = 0
			poison_ready = false
			poison_in_selection = false
# ======================
# Otros
# ======================
func _process(delta: float) -> void:
	if ulti_active and bar:
		var regen = 20 * delta
		bar.value = min(bar.value + regen, bar.max_value)
		GameState.set_vida(player_id, bar.value)
func _disable_stream_loop(player: AudioStreamPlayer2D) -> void:
	if player == null: return
	var s = player.stream
	if s == null: return
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
	var s_copy = s.duplicate(true)
	if "loop_mode" in s_copy:
		s_copy.loop_mode = 0
	elif "loop" in s_copy:
		s_copy.loop = false
	elif "loop_enabled" in s_copy:
		s_copy.loop_enabled = false
	player.stream = s_copy
<<<<<<< HEAD
func _end_dash() -> void:
	_is_dashing = false
	invulnerable = false
	velocity = Vector2.ZERO

	# Volver a idle si no hay input
	if animated_sprite and animated_sprite.animation == "dash":
		animated_sprite.play("idle")
=======
# ======================
# Dash
# ======================
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
func _start_dash(direction: Vector2) -> void:
	_is_dashing = true
	_dash_timer = dash_duration
	_dash_cooldown_timer = dash_cooldown
	_dash_dir = direction.normalized()
<<<<<<< HEAD

	# Opcional: invulnerable en dash
	invulnerable = true

	# Animación de dash
	if animated_sprite and animated_sprite.animation != "dash":
		animated_sprite.play("dash")

	# Opcional: sonido dash
	if has_node("sonido_dash"):
		$sonido_dash.play()
		
func _play_punch_sfx() -> void:
	if punchs:
		var p = _punch_variations[randi() % _punch_variations.size()]
		punchs.pitch_scale = p
		punchs.play()
		
func _enter_poison_selection() -> void:
	# Protecciones: no permitir si muerto, sin input o flotando
	if dead or not allow_input or floating:
		return

	selecting_poison = true
	poison_preview = Node2D.new()

	if animated_sprite:
		animated_sprite.play("lanzar")
		if has_node("Punch_left"):
			$Punch_left.visible = false
		if has_node("Punch_right"):
			$Punch_right.visible = false

	# Crear el sprite de preview
	var sprite := Sprite2D.new()
	sprite.texture = preload("res://Assets/art/sprites/Particulas/botella2.png")
	sprite.scale = Vector2(1.5, 1.5)
	sprite.centered = true
	poison_preview.add_child(sprite)
	get_tree().current_scene.add_child(poison_preview)
	poison_preview.global_position = self.global_position + Vector2(60 * _facing, -30)


# CANCELAR PRELUDIO
# =========================
func _cancel_poison_selection():
	# Elimina preview si existe
	if is_instance_valid(poison_preview):
		poison_preview.queue_free()
	poison_preview = null

	selecting_poison = false

	# Asegúrate de que los puños vuelvan a ser visibles
	if has_node("Punch_left"):
		$Punch_left.visible = true
	if has_node("Punch_right"):
		$Punch_right.visible = true

	# Animación idle si estaba lanzando
	if animated_sprite and animated_sprite.animation == "lanzar":
		animated_sprite.play("idle")

		
		
		
func _on_poison_timer_timeout():
	# Solo cargar si no está en cooldown
	if _poison_cooldown_remaining <= 0 and not poison_ready:
		poison_charge = clamp(poison_charge + 1, 0, poison_max_charge)
		veneno_couldown.max_value = poison_max_charge
		veneno_couldown.value = poison_charge

		if poison_charge >= poison_max_charge:
			poison_ready = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("area_veneno") and poison_ready:
		if not poison_in_selection:
			# Primera vez → activar preludio (preview/botella)
			_enter_poison_selection()
			poison_in_selection = true
		else:
			# Segunda vez → confirmar lanzamiento
			_activate_poison()
			_cancel_poison_selection()
			# Reiniciar cooldown
			poison_charge = 0
			veneno_couldown.value = 0
			poison_ready = false
			poison_in_selection = false




func _activate_poison() -> void:
	if poison_area_scene == null or poison_preview == null:
		return

	var poison_instance = poison_area_scene.instantiate()
	get_tree().current_scene.add_child(poison_instance)
	poison_instance.global_position = poison_preview.global_position

	# Aseguramos que los puños vuelvan a aparecer
	_cancel_poison_selection()



# COLOCAR EL VENENO
# =========================

func _place_poison_area():
	var poison_instance = poison_area_scene.instantiate()
	get_tree().current_scene.add_child(poison_instance)
	poison_instance.global_position = poison_preview.global_position

	_cancel_poison_selection()

	# Resetear barra para cooldown
	poison_ready = false
	poison_charge = 0
	_poison_cooldown_remaining = poison_cooldown_duration

	veneno_couldown.max_value = poison_cooldown_duration
	veneno_couldown.value = poison_cooldown_duration


func _on_poison_charged():
	poison_ready = true
=======
	invulnerable = true
	if animated_sprite.animation != "dash":
		animated_sprite.play("dash")
	if has_node("sonido_dash"):
		$sonido_dash.play()
func _end_dash() -> void:
	_is_dashing = false
	invulnerable = false
	velocity = Vector2.ZERO
	if animated_sprite.animation == "dash":
		_play_anim_safe("idle")
>>>>>>> d981ae4c943863d705e04fed50700f9a292b1771
