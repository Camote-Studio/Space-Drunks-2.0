extends Node2D

var SPEED := 200
var alien: CharacterBody2D
var alien_2: CharacterBody2D

@onready var progress_bar_alien_1: ProgressBar = null
@onready var progress_bar_alien_2: ProgressBar = null

func _ready() -> void:
	alien = get_tree().get_first_node_in_group("player")
	alien_2 = get_tree().get_first_node_in_group("player_2")
	
	if alien:
		# Ajusta el path al ProgressBar correcto dentro de Player_1
		if not alien.is_connected("damage", Callable(self, "_on_alien_damage")):
			alien.connect("damage", Callable(self, "_on_alien_damage"))
	
	if alien_2:
		# Ajusta el path al ProgressBar correcto dentro de Player_2
		if not alien_2.is_connected("damage", Callable(self, "_on_alien_damage")):
			alien_2.connect("damage", Callable(self, "_on_alien_damage"))
		
func _process(delta: float) -> void:
	position += transform.x * SPEED * delta

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Recibiste un impacto de bala de gravedad, estás flotando. Has perdido vida.")
		body.emit_signal("damage", 20.0, 'bala_gravedad')
	if body.is_in_group("player_2"):
		print("Recibiste un impacto de bala de gravedad, estás flotando. Has perdido vida.")
		body.emit_signal("damage", 20.0, 'bala_gravedad')
