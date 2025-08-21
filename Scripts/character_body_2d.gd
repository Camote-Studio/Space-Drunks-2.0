extends CharacterBody2D

signal damage(value: float)
var speed := 400
@onready var bar: ProgressBar = $ProgressBar_alien_1


func _ready() -> void:
	if not is_connected("damage", Callable(self, "_on_damage")):
		connect("damage", Callable(self, "_on_damage"))

func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("left_player_1", "right_player_1", "up_player_1", "down_player_1")
	velocity = direction * speed
	move_and_slide()

func _on_damage(amount: float) -> void:
	if bar:
		bar.value = clamp(bar.value - amount, bar.min_value, bar.max_value)

func _on_damage_enemy_body_entered(body: Node2D) -> void:
	if body.is_in_group("gun_enemy"):
		emit_signal("damage", 20.0)
