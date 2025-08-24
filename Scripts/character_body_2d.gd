extends CharacterBody2D

signal damage(amount: float, source: String)

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

var original_layer
var original_mask

func _ready() -> void:
	original_layer = collision_layer
	original_mask = collision_mask
	if not is_connected("damage", Callable(self, "_on_damage")):
		connect("damage", Callable(self, "_on_damage"))
	animated_sprite.play("idle")

func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("left_player_1", "right_player_1", "up_player_1", "down_player_1")
	
	if controls_inverted:
		direction = -direction
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

	if not floating:
		move_and_slide()
	else:
		_handle_floating(delta)

func _on_damage(amount: float, source: String) -> void:
	if bar:
		bar.value = clamp(bar.value - amount, bar.min_value, bar.max_value)

	if source == "bala":
		controls_inverted = true
		invert_timer = invert_duration
		print("Jugador invertido por impacto de bala")
	elif source == "bala_gravedad":
		floating = true
		invulnerable = true
		invul_timer = invul_duration

func _on_damage_enemy_body_entered(body: Node2D) -> void:
	if body.is_in_group("gun_enemy"):
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
		rotation = 0
		global_position.y = float_start_y
		set_collision_layer(original_layer)
		set_collision_mask(original_mask)
