extends CharacterBody2D

signal damage(value: float, source: String) 
var speed := 400
@onready var bar: ProgressBar = $"../CanvasLayer/ProgressBar_alien_1"
var controls_inverted := false
var invert_duration := 2.0 
var invert_timer := 0.0

func _ready() -> void:
	if not is_connected("damage", Callable(self, "_on_damage")):
		connect("damage", Callable(self, "_on_damage"))

func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("left_player_1", "right_player_1", "up_player_1", "down_player_1")
	if controls_inverted:
		direction.x = -direction.x
		direction.y = -direction.y
		invert_timer -= delta
		if invert_timer <= 0.0:
			controls_inverted = false 
	
	
	velocity = direction * speed
	move_and_slide()
	

func _on_damage(amount: float, source: String) -> void:
	
	if bar:
		bar.value = clamp(bar.value - amount, bar.min_value, bar.max_value)
	if source == "bala":  # 👈 solo si el daño viene de una bala
		controls_inverted = true
		invert_timer = invert_duration
		print("jugador invertido por impacto de bala")

func _on_damage_enemy_body_entered(body: Node2D) -> void:
	if body.is_in_group("gun_enemy"):
		emit_signal("damage", 20.0)
