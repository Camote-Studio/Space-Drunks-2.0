extends CanvasLayer

@export var player1: CharacterBody2D
@export var player2: CharacterBody2D
@export var main_cam: Camera2D

# UI y cámaras del peek 1
@onready var peek1: Control = $Peek1
@onready var circle1: TextureRect = $Peek1/Circle
@onready var svp1: SubViewport = $SVP1
@onready var peek_cam1: Camera2D = $SVP1/PeekCamera1

# UI y cámaras del peek 2
@onready var peek2: Control = $Peek2
@onready var circle2: TextureRect = $Peek2/Circle
@onready var svp2: SubViewport = $SVP2
@onready var peek_cam2: Camera2D = $SVP2/PeekCamera2


func _ready() -> void:
	# Chequeo rápido para ver si las rutas existen:
	_dbg(peek1,  "Peek1")
	_dbg(circle1,"Peek1/Circle")
	_dbg(svp1,   "SVP1")
	_dbg(peek_cam1, "SVP1/PeekCamera1")

	_dbg(peek2,  "Peek2")
	_dbg(circle2,"Peek2/Circle")
	_dbg(svp2,   "SVP2")
	_dbg(peek_cam2, "SVP2/PeekCamera2")

	# Configuración jugador 1
	_setup_peek(svp1, circle1, peek1, peek_cam1)
	# Configuración jugador 2
	_setup_peek(svp2, circle2, peek2, peek_cam2)

func _dbg(n: Node, where: String) -> void:
	if n == null:
		push_error("[Peek] Nodo nulo: " + where)

func _setup_peek(svp: SubViewport, circle: TextureRect, peek: Control, cam: Camera2D) -> void:
	# Si algo está nulo, no seguimos (evita el crash y te avisa en la consola)
	if svp == null or circle == null or peek == null or cam == null:
		push_error("[Peek] Algún parámetro llegó nulo. svp=%s circle=%s peek=%s cam=%s"
			% [str(svp), str(circle), str(peek), str(cam)])
		return

	# SubViewport.size es Vector2i en Godot 4
	svp.size = Vector2i(128, 128)
	svp.world_2d = get_viewport().world_2d
	svp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS

	# Muestra el SubViewport en el círculo
	circle.texture = svp.get_texture()
	# Para Controls, puedes usar size directamente (Vector2); si lo prefieres:
	# circle.custom_minimum_size = Vector2(128, 128)
	# peek.custom_minimum_size   = Vector2(128, 128)
	circle.size = Vector2(128, 128)
	peek.size   = Vector2(128, 128)

	peek.visible = false

	cam.enabled = true
	cam.make_current()
