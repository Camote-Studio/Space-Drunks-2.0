extends Area2D

signal collected(player_id)  # Señal que indica qué jugador recogió la moneda

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.is_in_group("player") or body.is_in_group("player_2"):  # Asegúrate que tus jugadores estén en el grupo "player"
		body.collect_coin()
		emit_signal("collected", body.name)  # Opcional: para UI u otros efectos
		queue_free()  # Desaparece la moneda
