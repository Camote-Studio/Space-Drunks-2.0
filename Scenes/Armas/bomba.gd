extends RigidBody2D

@export var target_y: float = 0.0
@export var damage: float = 50.0

@export var bounce_count: int = 3         # rebotes antes de explotar (ahora 4 en vez de 2)
@export var bounce_strength: float = 280.0 # fuerza del primer rebote (más alto)
@export var bounce_decay: float = 0.6      # cuanto se reduce la fuerza en cada rebote (0.6 = 60%)

var bounces_done: int = 0
var exploded: bool = false

func _physics_process(delta: float) -> void:
	if exploded:
		return

	# Si toca el suelo
	if global_position.y >= target_y:
		if bounces_done < bounce_count:
			# Rebote más fuerte y con decaimiento progresivo
			var strength = bounce_strength * pow(bounce_decay, bounces_done)
			linear_velocity.y = -strength
			bounces_done += 1
		else:
			_explode()

func _explode() -> void:
	if exploded:
		return
	exploded = true

	print("[BOMBA] ¡Explota en posición ", global_position, "!")

	var explosion_scene = preload("res://Scenes/Armas/explosion.tscn")
	var explosion = explosion_scene.instantiate()
	get_parent().add_child(explosion)
	explosion.global_position = global_position

	queue_free()
