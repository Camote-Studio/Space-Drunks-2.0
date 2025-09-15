extends Node2D

@export var bullet_scene: PackedScene                      # asigna la bala normal en el Inspector
@export var cooldown: float = 0.2
@export var offset_right := Vector2(20, 20)
@export var offset_left  := Vector2(-20, 20)

# Dónde está el AnimatedSprite2D del jugador
@export var sprite_path: NodePath = ^"../AnimatedSprite2D"

# “modo electroshock” (la bala debe soportarlo; si no, lo ignora)
@export var shock_bullets := true
@export var shock_duration := 1.5
@export var shock_factor   := 0.35

var can_fire := true
@onready var timer: Timer = $Timer

# cachea referencias con seguridad
var _sprite: AnimatedSprite2D
var _muzzle_sprite: Sprite2D

func _ready() -> void:
	timer.one_shot = true
	timer.wait_time = cooldown
	if not timer.is_connected("timeout", Callable(self, "_on_timer_timeout")):
		timer.connect("timeout", Callable(self, "_on_timer_timeout"))

	_sprite = get_node_or_null(sprite_path) as AnimatedSprite2D
	# si no lo encontró por path, prueba con el padre
	if _sprite == null:
		_sprite = get_parent().get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

	_muzzle_sprite = $Sprite2D if has_node("Sprite2D") else null

func _process(_dt: float) -> void:
	var flip := false
	if _sprite:
		flip = _sprite.flip_h
	else:
		# si no hay sprite, no falles
		flip = false

	if _muzzle_sprite:
		_muzzle_sprite.flip_h = flip
	position = offset_left if flip else offset_right

	if Input.is_action_just_pressed("fired") and can_fire:
		$electrogun.play()
		_fire(flip)

func _fire(is_flipped: bool) -> void:
	if bullet_scene == null:
		push_warning("[Gun] bullet_scene no asignado")
		return

	var b = bullet_scene.instantiate()
	get_parent().get_parent().add_child(b)
	b.global_position = global_position
	b.rotation_degrees = 180 if is_flipped else 0

	# Si la bala soporta estos campos, se los pasamos (si no, no pasa nada)
	if "dir" in b: b.dir = Vector2.LEFT if is_flipped else Vector2.RIGHT
	if "shock_enabled" in b:   b.shock_enabled = shock_bullets
	if "shock_duration" in b:  b.shock_duration = shock_duration
	if "shock_factor" in b:    b.shock_factor = shock_factor

	can_fire = false
	timer.start()

func _on_timer_timeout() -> void:
	can_fire = true
