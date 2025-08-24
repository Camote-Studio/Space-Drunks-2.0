extends Node2D
var SPEED := 200

@onready var progress_bar_alien_1: ProgressBar = $"../Player_1/ProgressBar_alien_1"
@onready var progress_bar_alien_2: ProgressBar = $"../Player_2/ProgressBar_alien_2"

var alien : CharacterBody2D
var alien_2 : CharacterBody2D

func _ready() -> void:
	alien = get_tree().get_first_node_in_group("player")
	alien_2 = get_tree().get_first_node_in_group("player_2")
	if alien and not alien.is_connected("damage", Callable(self, "_on_alien_damage")):
		alien.connect("damage", Callable(self, "_on_alien_damage"))
		
	if alien_2 and not alien_2.is_connected("damage", Callable(self, "_on_alien_damage")):
		alien_2.connect("damage", Callable(self, "_on_alien_damage"))
		
func _process(delta: float) -> void:
	position += transform.x * SPEED * delta

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Recibiste un impacto alien flaco! Has perdido vida.")
		print("recibiste una bala.")
		body.emit_signal("damage", 20.0,'bala')
	if body.is_in_group("player_2"):
		print("Recibiste un impacto alien gordo! Has perdido vida.")
		body.emit_signal("damage", 20.0,'bala')
