extends Area2D

@export var damage: float = 50.0
@export var knockback_force: float = 110.0   # fuerza del empuje

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	# Reproducir animación y sonido
	if sprite:
		sprite.play("explode")
		sprite.animation_finished.connect(_on_animation_finished)
	if audio:
		audio.play()

	# Conectar señal de detección de cuerpos
	if not self.is_connected("body_entered", Callable(self, "_on_body_entered")):
		self.connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	print("[EXPLOSIÓN] Entró en área: ", body.name)

	if body.is_in_group("enemy_1") or body.is_in_group("enemy_2") \
	or body.is_in_group("enemy_3") or body.is_in_group("enemy_4") \
	or body.is_in_group("enemy_5") or body.is_in_group("boss"):

		# --- Aplicar daño ---
		if body.has_signal("damage"):
			body.emit_signal("damage", damage)
			print("[EXPLOSIÓN] Daño aplicado a ", body.name)

		# --- Aplicar empuje (dirección opuesta a la bomba) ---
		var dir = (global_position - body.global_position).normalized()
		if body is RigidBody2D:
			body.apply_impulse(dir * knockback_force, Vector2.ZERO)
		elif body.has_method("apply_knockback"):
			body.apply_knockback(dir * knockback_force)

func _on_animation_finished() -> void:
	queue_free()
