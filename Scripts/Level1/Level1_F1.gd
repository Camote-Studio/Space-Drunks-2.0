extends Node2D

@onready var portal = $Portal # Ajusta la ruta si tu portal está en otra parte
var final_event_triggered: bool = false

func _ready():
	# Reproduce animación de sombras
	$"Sombras_transición/AnimationPlayer".play("Sombra_off")
	
	# Reproduce música
	var music = preload("res://Assets/music/funk-house-retro-groovy-dance-216533.mp3")
	SoundEffectManager.music_player.stream = music
	SoundEffectManager.music_player.play()
	
	# Conectar la señal body_entered de la zona final


# Función que detecta al jugador entrando al área final
func _on_final_nivel_body_entered(body: Node) -> void:
	print("Entró:", body.name, " grupos:", body.get_groups())
	if (body.is_in_group("player") or body.is_in_group("player_2")) and not final_event_triggered:
		final_event_triggered = true
		print("jugador", body.name, "pasó el área para bloquear")
		
		# Bloquear el portal al llegar al área final
		if portal.has_method("lock_portal"):
			portal.lock_portal()
		
		# Empezar a revisar si quedan enemigos
		check_remaining_enemies()


# Función que revisa enemigos y desbloquea el portal cuando ya no quedan
func check_remaining_enemies():
	# Mientras haya enemigos, espera
	while not get_tree().get_nodes_in_group("enemies").is_empty():
		await get_tree().create_timer(0.5).timeout
	
	# Cuando no queda ninguno, desbloquear portal
	if portal.has_method("unlock_portal"):
		portal.unlock_portal()
		print("Todos los enemigos eliminados. Portal desbloqueado.")
