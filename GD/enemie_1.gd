extends CharacterBody2D

signal damage(value: float)

var speed := 300
var player: CharacterBody2D = null
const BULLET_ENEMY_1 = preload("res://TSCN/gun_enemy_1.tscn")
@onready var label: Label = $Label
@onready var bar_3: ProgressBar = $ProgressBar_enemy
@onready var anim: AnimatedSprite2D = $Sprite2D

var min_range := 250.0
var max_range := 350.0
var attack_range := 500.0
var bullet_speed := 700.0

var _stack_value := 0.0
var _stack_timer: Timer
var _label_base_pos := Vector2.ZERO
var _tween: Tween
var dead:= false

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	$gun_timer.start()
	add_to_group("enemy_1")
	if not is_connected("damage", Callable(self, "_on_damage")):
		connect("damage", Callable(self, "_on_damage"))
	_stack_timer = Timer.new()
	_stack_timer.one_shot = true
	add_child(_stack_timer)
	_stack_timer.connect("timeout", Callable(self, "_on_stack_timeout"))
	_label_base_pos = label.position
	label.visible = false
	if anim and not anim.is_connected("animation_finished", Callable(self, "_on_AnimatedSprite2D_animation_finished")):
		anim.connect("animation_finished", Callable(self, "_on_AnimatedSprite2D_animation_finished"))

func _physics_process(delta: float) -> void:
	if player == null:
		return
	var to_player: Vector2 = player.global_position - global_position
	var dist := to_player.length()
	look_at(player.global_position)
	rotation_degrees = wrap(rotation_degrees, 0, 360)
	if dist > max_range:
		velocity = to_player.normalized() * speed
	elif dist < min_range:
		velocity = -to_player.normalized() * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()

func _on_gun_timer_timeout() -> void:
	if player == null:
		return
	var to_player: Vector2 = player.global_position - global_position
	if to_player.length() > attack_range:
		return
	var bullet_instance = BULLET_ENEMY_1.instantiate()
	get_parent().add_child(bullet_instance)
	bullet_instance.global_position = global_position
	bullet_instance.rotation = to_player.angle()

func _on_damage(amount: float) -> void:
	if bar_3:
		bar_3.value = clamp(bar_3.value - amount, bar_3.min_value, bar_3.max_value)
	_stack_value += amount
	label.text = str(int(_stack_value))
	label.visible = true
	label.position = _label_base_pos
	label.scale = Vector2.ONE
	var sum := int(_stack_value)
	var col := Color(1, 1, 1, 1)
	if sum <= 20:
		col = Color(1, 1, 1, 1)
	elif sum <= 40:
		col = Color(1, 1, 0, 1)
	else:
		col = Color(1, 0, 0, 1)
	label.modulate = col
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(label, "position:y", _label_base_pos.y - 18.0, 0.25)
	_tween.parallel().tween_property(label, "scale", Vector2(1.25, 1.25), 0.18)
	_tween.parallel().tween_property(label, "modulate:a", 0.0, 0.35).set_delay(0.05)
	_stack_timer.start(0.4)
	if not dead and bar_3 and bar_3.value <= bar_3.min_value:
		dead=true
		$Label.visible = false
		if has_node("gun_timer"):
			$gun_timer.stop() 
		velocity = Vector2.ZERO
		anim.play("explosion")
		$explosion_timer.start()

func _on_stack_timeout() -> void:
	_stack_value = 0.0
	label.visible = false

func _on_damage_enemy_body_entered(body: Node2D) -> void:
	if body.is_in_group("player_1_bullet"):
		emit_signal("damage", 10.0)

#func _on_sprite_2d_animation_finished() -> void:
	#if anim.animation == "explosion":
		#queue_free()

func _on_explosion_timer_timeout() -> void:
	queue_free()
