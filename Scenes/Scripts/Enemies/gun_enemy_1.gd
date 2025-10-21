extends Node2D
var SPEED := 200

@onready var progress_bar_alien_1: TextureProgressBar = $"../Player_1/ProgressBar_alien_1"
@onready var progress_bar_alien_2: TextureProgressBar = $"../Player_2/ProgressBar_alien_2"

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
		body.emit_signal("damage", 20.0,'bala')
	if body.is_in_group("player_2"):
		body.emit_signal("damage", 20.0,'bala')
