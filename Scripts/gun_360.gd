extends CharacterBody2D

# ======================
#       SEÑALES
# ======================
signal damage(amount: float, source: String)
signal muerte
signal deal_damage(amount: float, source: String)

# ======================
#       VARIABLES
# ======================
var coins: int = 0
@export var player_id: String = "player2"
@export var punch_damage_base: float = 10.0
var dead := false
var allow_input := true

# ======================
#       NODOS
# ======================
@onready var bar: TextureProgressBar = $"../CanvasLayer/ProgressBar_alien_2"
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var bar_ability_2: ProgressBar = $"../CanvasLayer/ProgressBar_ability_2"
@onready var coin_label: Label = $"../CanvasLayer/cont monedas2"
@onready var punch_left: Sprite2D = $Punch_left
@onready var punch_right: Sprite2D = $Punch_right
@onready var TimerUlti: Timer = $TimerUlti
@onready var TimerAutoPunch: Timer = $TimerAutoPunch
@onready var aura: CPUParticles2D = $AuraParticles

@export var punch_left_texture_1: Texture2D
@export var punch_left_texture_2: Texture2D
@export var punch_right_texture_1: Texture2D
@export var punch_right_texture_2: Texture2D

# ======================
#       PUÑOS / FACING
# ======================
var _facing := 1
var _base_left := Vector2.ZERO
var _base_right := Vector2.ZERO
var punch_side := true
var _hit_cooldowns := {}

# ======================
#       ULTI
# ======================
var ulti_active := false

# ======================
#       ESPADA
# ======================
@export var espada_scene: PackedScene
@export var espada_duracion: float = 15.0
var _sword_instance: Node2D = null
var _sword_active := false
var _sword_timer: Timer

# ======================
#       MOVIMIENTO
# ======================
var speed := 220

# ======================
#       READY
# ======================
func _ready() -> void:
	_base_left = punch_left.position
	_base_right = punch_right.position

	coins = GameState.get_coins(player_id)
	GameState.set_coins(player_id, coins)
	if coin_label:
		coin_label.text = str(coins)

	if bar_ability_2:
		bar_ability_2.min_value = 0
		bar_ability_2.max_value = 150
		bar_ability_2.value = 0

	if not is_connected("damage", Callable(self, "_on_damage")):
		connect("damage", Callable(self, "_on_damage"))

	animated_sprite.play("idle")

	if not is_in_group("players"):
		add_to_group("players")

	# Timer espada
	_sword_timer = Timer.new()
	_sword_timer.one_shot = true
	add_child(_sword_timer)
	if not _sword_timer.is_connected("timeout", Callable(self, "_revert_sword")):
		_sword_timer.connect("timeout", Callable(self, "_revert_sword"))

	# Timers ulti
	if not TimerUlti.is_connected("timeout", Callable(self, "_end_ulti")):
		TimerUlti.connect("timeout", Callable(self, "_end_ulti"))
	if not TimerAutoPunch.is_connected("timeout", Callable(self, "_ulti_punch")):
		TimerAutoPunch.connect("timeout", Callable(self, "_ulti_punch"))

	# Hitboxes ya conectadas vía Hitbox.gd
	# Solo ajustar monitoring inicial
	if has_node("Punch_left/Hitbox"):
		$Punch_left/Hitbox.monitoring = false
	if has_node("Punch_right/Hitbox"):
		$Punch_right/Hitbox.monitoring = false

	_set_facing(1)

	if aura:
		aura.emitting = false

# ======================
#       FACING
# ======================
func _set_facing(sign_dir: int) -> void:
	if sign_dir == 0: return
	_facing = sign_dir
	animated_sprite.flip_h = (_facing < 0)
	punch_left.flip_h = animated_sprite.flip_h
	punch_right.flip_h = animated_sprite.flip_h
	punch_left.position = Vector2(_base_left.x * _facing, _base_left.y)
	punch_right.position = Vector2(_base_right.x * _facing, _base_right.y)
	_update_sword_transform()

# ======================
#       PHYSICS PROCESS
# ======================
func _physics_process(delta: float) -> void:
	if dead:
		velocity = Vector2.ZERO
		return

	var direction = Vector2.ZERO
	if allow_input:
		direction = Input.get_vector("left_player_2", "right_player_2", "up_player_2", "down_player_2")

	if allow_input and Input.is_action_just_pressed("jump_2") and not ulti_active:
		print("[PLAYER2] Se presionó jump_2 -> Activando ULTI")
		_activate_ulti()

	velocity = direction * speed
	move_and_slide()

	if abs(direction.x) > 0.01:
		_set_facing(sign(direction.x))

	animated_sprite.position.y = -0
	punch_left.position.y = _base_left.y
	punch_right.position.y = _base_right.y
	_update_sword_transform()

# ======================
#       PUÑOS / ULTI
# ======================
func _activate_ulti() -> void:
	if ulti_active or dead: return
	ulti_active = true
	print("[PLAYER2] ULTI activada")
	animated_sprite.play("ulti_pose")
	punch_left.texture = punch_left_texture_2
	punch_right.texture = punch_right_texture_2
	_show_aura()
	TimerUlti.start(5.0)
	TimerAutoPunch.start(0.05)

func _end_ulti() -> void:
	ulti_active = false
	print("[PLAYER2] ULTI terminada")
	if not dead:
		animated_sprite.play("idle")
	punch_left.texture = punch_left_texture_1
	punch_right.texture = punch_right_texture_1
	if aura: aura.emitting = false
	TimerAutoPunch.stop()

func _ulti_punch() -> void:
	if not ulti_active or dead: return
	if punch_side:
		_punch_left_attack()
	else:
		_punch_right_attack()
	punch_side = !punch_side
	_show_aura()

func _show_aura():
	if aura:
		aura.emitting = true
		var t = create_tween()
		t.tween_callback(func(): aura.emitting = false).set_delay(0.12)

func _punch_left_attack():
	if dead: return
	print("[PLAYER2] Ataque PUÑO IZQUIERDO")
	var t = create_tween()
	t.tween_property(punch_left, "position", _base_left + Vector2(45 * _facing, 0), 0.05)
	t.tween_property(punch_left, "position", _base_left, 0.05)
	if has_node("Punch_left/Hitbox"):
		$Punch_left/Hitbox.monitoring = true
		var hitbox = $Punch_left/Hitbox
		t.tween_callback(func(): hitbox.monitoring = false).set_delay(0.05)

func _punch_right_attack():
	if dead: return
	print("[PLAYER2] Ataque PUÑO DERECHO")
	var t = create_tween()
	t.tween_property(punch_right, "position", _base_right + Vector2(45 * _facing, 0), 0.05)
	t.tween_property(punch_right, "position", _base_right, 0.05)
	if has_node("Punch_right/Hitbox"):
		$Punch_right/Hitbox.monitoring = true
		var hitbox = $Punch_right/Hitbox
		t.tween_callback(func(): hitbox.monitoring = false).set_delay(0.05)

# ======================
#       HITBOX / DAÑO
# ======================
func _on_hitbox_area_entered(area: Area2D, punch_side: String) -> void:
	if dead: return
	var damage_amount: float = punch_damage_base
	if ulti_active:
		damage_amount = 50.0

	var key = str(area.get_instance_id()) + "_" + punch_side
	var now_frame = Engine.get_physics_frames()
	if _hit_cooldowns.has(key) and now_frame - _hit_cooldowns[key] < 3:
		return
	_hit_cooldowns[key] = now_frame

	if area.is_in_group("enemies") and area.has_method("_on_damage"):
		area._on_damage(damage_amount, punch_side)
		print("[PLAYER2] Golpe aplicado a ", area.name, " con daño: ", damage_amount, " (", punch_side, ")")

# ======================
#       ESPADA
# ======================
func activate_sword_for(seconds: float = -1.0) -> void:
	if dead: return
	if espada_scene == null:
		push_warning("[P2] No hay espada_scene asignada en el Inspector.")
		return
	if seconds <= 0.0:
		seconds = espada_duracion

	if _sword_active and is_instance_valid(_sword_instance):
		_sword_timer.start(seconds)
		return

	_sword_instance = espada_scene.instantiate() as Node2D
	add_child(_sword_instance)
	_update_sword_transform()

	punch_left.visible = false
	punch_right.visible = false

	if _sword_instance.has_signal("dealt_damage") and not _sword_instance.is_connected("dealt_damage", Callable(self, "_on_sword_dealt_damage")):
		_sword_instance.connect("dealt_damage", Callable(self, "_on_sword_dealt_damage"))

	_sword_active = true
	_sword_timer.start(seconds)

func _revert_sword() -> void:
	if is_instance_valid(_sword_instance):
		_sword_instance.queue_free()
		_sword_instance = null
	_sword_active = false
	if not dead:
		punch_left.visible = true
		punch_right.visible = true

func _update_sword_transform() -> void:
	if not _sword_active or not is_instance_valid(_sword_instance): return
	var anchor := Vector2(abs(_base_right.x) * _facing, _base_right.y)
	_sword_instance.position = anchor
	_sword_instance.scale.x = abs(_sword_instance.scale.x) * float(_facing)

func _on_sword_dealt_damage(target: Node2D, amount: float) -> void:
	if target.is_in_group("enemies") and target.has_method("_on_damage"):
		target._on_damage(amount, "espada")

# ======================
#       DAÑO / MUERTE / MONEDAS
# ======================
func _on_damage(amount: float, source: String = "desconocido") -> void:
	if dead: return
	if bar:
		bar.value = clamp(bar.value - amount, bar.min_value, bar.max_value)
		if bar.value <= bar.min_value:
			_die()
	print("[PLAYER2] Recibió daño: ", amount, " Fuente: ", source)

func _die() -> void:
	dead = true
	allow_input = false
	velocity = Vector2.ZERO
	_revert_sword()
	animated_sprite.play("death")
	print("[PLAYER2] MUERTO")
	emit_signal("muerte")

func collect_coin(amount: int = 1) -> void:
	coins += amount
	if coin_label:
		coin_label.text = str(coins)
	GameState.set_coins(player_id, coins)
	print("[PLAYER2] Moneda recogida, total: ", coins)
