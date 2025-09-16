extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var player: CharacterBody2D

func _ready() -> void:
	set_physics_process(false) # solo queremos lógica visual en _process
	# Busca por grupo (más seguro que por nombre):
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		# Fallback: intenta por nombre, recursivo, tras un frame
		call_deferred("_late_grab_player")

func _late_grab_player() -> void:
	player = get_parent().find_child("player", true, false) as CharacterBody2D

func _process(delta: float) -> void:
	if player == null or animated_sprite_2d == null:
		return

	# Usa global_position para no depender de transforms del padre
	var dx := player.global_position.x - global_position.x

	# Deadzone para no estar flip/flop cuando están alineados verticalmente
	if abs(dx) > 2.0:
		# Si tu sprite por defecto "mira a la derecha", esto es correcto:
		animated_sprite_2d.flip_h = dx < 0.0

	# Nunca te pongas de cabeza
	animated_sprite_2d.flip_v = false
