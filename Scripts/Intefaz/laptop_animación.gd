# Laptop.gd
# Adjunta este script al nodo raíz CanvasLayer de tu escena de transición.

extends CanvasLayer

# --- Variables ---

# Referencia al AnimationPlayer. 
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Variable para almacenar la ruta de la escena a la que nos dirigimos.
var _target_scene_path: String = ""

# --- Funciones de Godot ---

func _ready() -> void:
	# Nos aseguramos de que la capa de transición esté oculta al iniciar el juego.
	visible = false


# --- Funciones Personalizadas ---

# Esta es la función PÚBLICA que llamarás desde cualquier otro script (como tu menú).
func change_scene(target_path: String, animation_name: String) -> void:
	# Guardamos la ruta de la escena de destino para usarla después de la animación.
	_target_scene_path = target_path
	
	# Hacemos visible toda la capa de transición (el CanvasLayer y sus hijos).
	visible = true
	
	# Reproducimos la animación solicitada (ej: "abrir_laptop" o "Sombra_on").
	animation_player.play("abrir_laptop")
	
	# Aquí está la magia: 'await' pausa la ejecución de ESTA función
	# hasta que el AnimationPlayer emita la señal "animation_finished".
	await animation_player.animation_finished
	
	# Una vez que la animación ha terminado, procedemos a cambiar la escena.
	var error = get_tree().change_scene_to_file("res://Scenes/Interfaz/Tutorial.tscn")
	
	# Comprobación de errores por si la ruta del archivo es incorrecta.
	if error!= OK:
		print("Error al cambiar a la escena: ", "res://Scenes/Interfaz/Tutorial.tscn")
		# Si hay un error, nos ocultamos para no bloquear el juego.
		visible = false
		return

	# Después de que la nueva escena se ha cargado, queremos que la transición desaparezca.

	visible = false
