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
	# Configuración jugador 1
	_setup_peek(svp1, circle1, peek1, peek_cam1)

	# Configuración jugador 2
	_setup_peek(svp2, circle2, peek2, peek_cam2)


func _setup_peek(svp: SubViewport, circle: TextureRect, peek: Control, cam: Camera2D) -> void:
	svp.size = Vector2i(128, 128)
	svp.world_2d = get_viewport().world_2d
	svp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	circle.texture = svp.get_texture()
	circle.size = Vector2(128, 128)
	peek.size = Vector2(128, 128)
	peek.visible = false
	cam.enabled = true
	cam.make_current()


func _process(delta: float) -> void:
	if player1:
		_update_peek(player1, peek1, peek_cam1)
	if player2:
		_update_peek(player2, peek2, peek_cam2)


func _update_peek(player: CharacterBody2D, peek: Control, cam: Camera2D) -> void:
	var off := _is_offscreen(player)
	peek.visible = off
	if off:
		cam.global_position = player.global_position
		if main_cam:
			cam.zoom = main_cam.zoom
			cam.rotation = main_cam.rotation


func _is_offscreen(n: Node2D) -> bool:
	var cam := main_cam
	if cam == null:
		cam = get_viewport().get_camera_2d()
		if cam == null:
			return false
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var half_world := (vp_size * 0.5) / cam.zoom
	var center := cam.get_screen_center_position()
	var minp := center - half_world
	var maxp := center + half_world
	var p := n.global_position
	return p.x < minp.x or p.x > maxp.x or p.y < minp.y or p.y > maxp.y
