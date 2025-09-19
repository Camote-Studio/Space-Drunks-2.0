extends CharacterBody2D # player 1
var _flotar_sound_played := false

signal damage(amount: float, source: String)
signal muerte
@onready var shop: Control = $"../CanvasLayer/UI_abilities"

# --- GUN / ULTI ---
@onready var gun = $Gun
@onready var ulti_timer: Timer = $UltiTimer

var coins: int = 0
@export var player_id: String = "player1" # Identificador único

@onready var gun_node: Node = $Gun
@onready var sonido_aturdido: AudioStreamPlayer2D = $sonido_aturdido
@onready var sonido_flotando: AudioStreamPlayer2D = $sonido_flotando
@onready var audio_disparo_metra: AudioStreamPlayer2D = $audio_disparo_metra
@onready var audio_recarga: AudioStreamPlayer2D = $audio_recarga
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

enum Estado { NORMAL, VENENO, ATURDIDO, ULTI, DEAD, FLOATING }
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
var is_using_ulti := false

# ====== Poder de disparo potenciado ======
var next_shot_powered := false
var power_bullet_scale := 1.8
var power_bullet_extra_damage := 20.0
@onready var visuals: Node2D = $Visuals

# =============== FUNCIÓN READY =============================
func _ready() -> void:
	_disable_stream_loop(sonido_flotando)


	# Configuración de timers
	if gun:
		print("✅ Gun detectado:", gun)
	else:
		push_error("❌ Gun no está conectado en Player")
		
	if ulti_timer:
		ulti_timer.one_shot = true
		if not ulti_timer.is_connected("timeout", Callable(self, "_on_ulti_timer_timeout")):
			ulti_timer.connect("timeout", Callable(self, "_on_ulti_timer_timeout"))

	coins = GameState.get_coins(player_id)
	GameState.set_coins(player_id, coins)
	if coin_label:
		coin_label.text = str(coins)

	if not is_connected("damage", Callable(self, "_on_damage")):
		connect("damage", Callable(self, "_on_damage"))

	# Animación por defecto
	if animated_sprite:
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
	
# =============== FUNCIÓN PHYSICS PROCEES ===================================
func _physics_process(delta: float) -> void:
	if dead:
		velocity = Vector2.ZERO
		return

	var direction = Vector2.ZERO

	if allow_input:
		direction = Input.get_vector("left_player_1", "right_player_1", "up_player_1", "down_player_1")

	if Input.is_action_just_pressed("jump") and not is_using_ulti:
		_activate_ulti()

	# --- Animaciones solo si NO estamos en ulti y no muertos ---
	if not is_using_ulti and not dead:
		_update_animation(direction)

	velocity = direction.normalized() * speed

	if not floating:
		velocity = direction * speed
		move_and_slide()
		# detener sonido de flotación si estaba sonando
		if sonido_flotando.playing:
			sonido_flotando.stop()
	else:
		_handle_floating(delta)


# ====================== FUNCIÓN UPDATE ANIMACIONES ===========================
func _update_animation(direction: Vector2) -> void:
	match estado_actual:
		Estado.VENENO:
			if animated_sprite.animation != "envenenado":
				animated_sprite.play("envenenado")
			if abs(direction.x) > 0:
				animated_sprite.flip_h = direction.x < 0

		Estado.ATURDIDO:
			var dir = -direction
			if animated_sprite.animation != "aturdio":
				animated_sprite.play("aturdio")
			if abs(dir.x) > abs(dir.y):
				animated_sprite.flip_h = dir.x < 0
			if not sonido_aturdido.playing:
				sonido_aturdido.play()

		Estado.NORMAL:
			if direction == Vector2.ZERO:
				animated_sprite.play("idle")
				$Gun.visible = true
			else:
				if abs(direction.x) > abs(direction.y):
					animated_sprite.play("caminar")
					animated_sprite.flip_h = direction.x < 0
					$Gun.visible = true
				elif direction.y < 0:
					animated_sprite.play("caminar_subir")
					$Gun.visible = false
				else:
					# si va hacia abajo, mostrar gun
					animated_sprite.play("caminar")
					$Gun.visible = true

			if sonido_aturdido.playing:
				sonido_aturdido.stop()
		
# ====================== FUNCIÓN DAÑO ===============================================
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
				if has_node("venenoTimer"):
					$venenoTimer.start(0.5)
		"bala":
			if estado_actual == Estado.NORMAL:
				estado_actual = Estado.ATURDIDO
				if has_node("AturdidoTimer"):
					$AturdidoTimer.start(2)
		"bala_gravedad":
			if sonido_flotando.playing:
				sonido_flotando.stop()
				if sonido_flotando.has_method("seek"):
					sonido_flotando.seek(0.0)

			_flotar_sound_played = false  # 🔹 fuerza a que vuelva a sonar la próxima vez
			floating = true
			invulnerable = true
			invul_timer = invul_duration



func _on_damage_enemy_body_entered(body: Node2D) -> void:
	if body.is_in_group("gun_enemy") and not invulnerable and not dead:
		emit_signal("damage", 20.0, "bala")

# ====================== FUNCIÓN FLOTAR ==========================================
func _handle_floating(delta: float) -> void:
	if floating:
		if not _flotar_sound_played:
			sonido_flotando.play()
			_flotar_sound_played = true
	else:
		_flotar_sound_played = false
		if sonido_flotando.playing:
			sonido_flotando.stop()
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

# ====================== FUNCIONES DE SOPORTE ============================= 
func gain_ability_from_attack(damage_dealt: float) -> void:
	if dead or bar_ability_1 == null: return
	bar_ability_1.value = clamp(bar_ability_1.value + max(0.0, damage_dealt), bar_ability_1.min_value, bar_ability_1.max_value)
	if bar_ability_1.value >= bar_ability_1.max_value:
		_power()

func gain_ability_from_shot() -> void:
	if dead or bar_ability_1 == null: return
	var shots_required := 10.0
	var gain := (bar_ability_1.max_value - bar_ability_1.min_value) / shots_required
	bar_ability_1.value = clamp(bar_ability_1.value + gain, bar_ability_1.min_value, bar_ability_1.max_value)
	if bar_ability_1.value >= bar_ability_1.max_value:
		_power()

func _power() -> void:
	if dead or next_shot_powered: 
		return

	if bar_ability_1 and not is_using_ulti and bar_ability_1.value >= bar_ability_1.max_value:
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

# ====================== FUNCIONES DE MUERTE / ESTADO ATACADO =====================
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
		# NO detener la animación para que quede permanente

	$"../CanvasLayer/Sprite2D".self_modulate = Color(1, 0, 0, 1)
	$"../CanvasLayer/Characater1Profile".texture = preload("res://Assets/art/sprites/complements_sprites/muerto_kirk.png")
	emit_signal("muerte")

func _on_aturdido_timer_timeout() -> void:
	if estado_actual == Estado.ATURDIDO:
		estado_actual = Estado.NORMAL
		if sonido_aturdido.playing:
			sonido_aturdido.stop()

func _on_veneno_timer_timeout() -> void:
	if estado_actual == Estado.VENENO:
		estado_actual = Estado.NORMAL

# ====================== FUNCIÓN PARA COLECCIONAR MONEDAS =======================
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

# ====================== FUNCIÓN DE ARMAS ESPECIALES ================================
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

# ====================== FUNCIÓN PARA ULTI =======================
func _activate_ulti() -> void:
	print("🔥 Ulti ACTIVADA")
	is_using_ulti = true
	allow_input = false

	if gun:
		gun.set_mode(gun.GunMode.TURRET)

	# 🔊 Sonido de recarga al sacar ulti
	if audio_recarga and not audio_recarga.playing:
		audio_recarga.play()

	if has_node("Visuals/AnimatedSprite2D"):
		var anim_sprite: AnimatedSprite2D = $Visuals/AnimatedSprite2D
		if anim_sprite.sprite_frames.has_animation("ulti_pose"):
			anim_sprite.stop()
			anim_sprite.play("ulti_pose")
		else:
			push_warning("Animación 'ulti_pose' no existe en AnimatedSprite2D")
	if ulti_timer:
		ulti_timer.start(5.0)



func _on_ulti_timer_timeout() -> void:
	print("⏱️ Ulti terminó → regresando a normal")
	is_using_ulti = false
	allow_input = true

	if gun and gun.has_method("set_mode"):
		gun.set_mode(gun.GunMode.PISTOL)

	# Regresar a idle solo si no estamos muertos
	if not dead and has_node("Visuals/AnimatedSprite2D"):
		var anim_sprite: AnimatedSprite2D = $Visuals/AnimatedSprite2D
		if anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation("idle"):
			anim_sprite.play("idle")
# Empuje temporal que no rompe la física
func push_temp(offset: Vector2) -> void:
	global_position += offset
	
# En tu script player.gd
func is_unable_to_act() -> bool:
	# Aquí pones tu propia lógica.
	return dead or not allow_input
func _disable_stream_loop(player: AudioStreamPlayer2D) -> void:
	if player == null:
		return
	var s = player.stream
	if s == null:
		return
	var s_copy = s.duplicate(true)
	if "loop_mode" in s_copy:
		s_copy.loop_mode = 0
	elif "loop" in s_copy:
		s_copy.loop = false
	elif "loop_enabled" in s_copy:
		s_copy.loop_enabled = false
	player.stream = s_copy
