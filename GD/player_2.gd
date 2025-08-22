extends CharacterBody2D
signal damage(value: float)
var speed := 400
@onready var bar_2: ProgressBar = $"../CanvasLayer/ProgressBar_alien_2"



func _ready() -> void:
	add_to_group("player_2")
	if not is_connected("damage", Callable(self, "_on_damage")):
		connect("damage", Callable(self, "_on_damage"))

func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("left_player_2", "right_player_2", "up_player_2", "down_player_2")
	velocity =direction * speed
	move_and_slide()


func _on_damage(amount: float) -> void:
	if bar_2:
		bar_2.value = clamp(bar_2.value - amount, bar_2.min_value, bar_2.max_value)

func _on_damage_enemy_body_entered(body: Node2D) -> void:
	if body.is_in_group("gun_enemy"):
		emit_signal("damage", 20.0)
