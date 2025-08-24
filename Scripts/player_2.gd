extends CharacterBody2D
signal damage(value: float)
var speed := 400
@onready var bar_2: ProgressBar = $"../CanvasLayer/ProgressBar_alien_2"
@onready var sprite_2d: Sprite2D = $Sprite2D
var controls_inverted := false
var invert_duration := 2.0 
var invert_timer := 0.0

func _ready() -> void:
	add_to_group("player_2")
	if not is_connected("damage", Callable(self, "_on_damage")):
		connect("damage", Callable(self, "_on_damage"))

func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("left_player_2", "right_player_2", "up_player_2", "down_player_2")
	if controls_inverted:
		direction.x = -direction.x
		direction.y = -direction.y
		invert_timer -= delta
		if invert_timer <= 0.0:
			controls_inverted = false 
	velocity =direction * speed

	# Flip horizontal cuando va hacia la izquierda
	if abs(direction.x) > 0.05:
		sprite_2d.flip_h = direction.x < 0
	move_and_slide()

func _on_damage(amount: float, source: String) -> void:
	if bar_2:
		bar_2.value = clamp(bar_2.value - amount, bar_2.min_value, bar_2.max_value)
	if source == "bala":  # 👈 solo si el daño viene de una bala
		controls_inverted = true
		invert_timer = invert_duration
		print("jugador invertido por impacto de bala")

func _on_damage_enemy_body_entered(body: Node2D) -> void:
	if body.is_in_group("gun_enemy"):
		emit_signal("damage", 20.0)
