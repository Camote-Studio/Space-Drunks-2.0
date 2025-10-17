extends Control # Make sure it's still a Control node

# ... (tus variables @export siguen aquí) ...
@export var final_boss: Node
@export var win_animation_player: AnimationPlayer
@export var transition_animation_player: AnimationPlayer
@export var scene_change_timer: Timer

var is_changing_scene: bool = false

func _ready():
	hide()
	# This node and its children will run even when the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if final_boss:
		final_boss.died.connect(on_boss_died)
	else:
		print("ERROR: El jefe no ha sido asignado al script de Ganaste en el Inspector.")

@export var mundo_del_juego: Node2D
@export var interfaz_juego: CanvasLayer # El nodo CanvasLayer que tiene la vida, etc.

func on_boss_died():
	# 1. Oculta TODO el juego y su UI con solo dos líneas.
	if mundo_del_juego:
		mundo_del_juego.hide()
	if interfaz_juego:
		interfaz_juego.hide()
	# 1. ¡Pausa el juego! Esto congela al jugador, la UI de vida, etc.
	get_tree().paused = true

	# 2. Hacemos visible la pantalla de victoria (que ignorará la pausa).
	show()
	
	transition_animation_player.play("Sombra_on")
	
	await transition_animation_player.animation_finished
	
	# 3. Reproducimos la animación de "GANASTE".
	win_animation_player.play("GANASTE")

	# 4. Iniciamos el contador para cambiar de escena.
	scene_change_timer.start()

# Esta función NO necesita cambios
func _on_scene_change_timer_timeout():
	transition_animation_player.play("Sombra_off")
	await transition_animation_player.animation_finished
	
	# ¡IMPORTANTE! Despausa el juego antes de cambiar de escena.
	get_tree().paused = false 
	get_tree().change_scene_to_file("res://Scenes/Interfaz/GANASTE.tscn")

# La función _process también necesita despausar el juego
func _process(delta):
	if Input.is_action_just_pressed("start") and not is_changing_scene:
		
		is_changing_scene = true
		
		transition_animation_player.play("Sombra_off")
		await transition_animation_player.animation_finished
		
		# ¡IMPORTANTE! Despausa el juego antes de volver al menú.
		get_tree().paused = false
		get_tree().change_scene_to_file("res://Scenes/Interfaz/Menú/Menu.tscn")
