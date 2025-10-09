extends Node

func _ready():
	$"../Player_1".muerte.connect(_on_player_died)
	$"../Player_2".muerte.connect(_on_player_died)

var dead_count = 0

func _on_player_died():
	dead_count += 1
	if dead_count >= 2:  # Ambos jugadores muertos
		_game_over()

func _game_over():
	# Crear un Timer temporal
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	add_child(timer)
	timer.start()
	
	# Esperar a que termineb
	await timer.timeout
	$"Sombras_transición/AnimationPlayer".play("Sombra_off")
	# Cambiar de escena después del delay
	get_tree().change_scene_to_file("res://Scenes/Interfaz/F_enelchat.tscn")
