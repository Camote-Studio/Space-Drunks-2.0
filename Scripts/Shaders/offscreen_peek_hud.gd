extends CanvasLayer

@export var player: CharacterBody2D
@export var main_cam: Camera2D

@onready var peek: Control = $Peek
@onready var circle: TextureRect = $Peek/Circle
@onready var svp: SubViewport = $SVP
@onready var peek_cam: Camera2D = $SVP/PeekCamera

func _ready() -> void:
	svp.size = Vector2i(128, 128)
	svp.world_2d = get_viewport().world_2d
	svp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	circle.texture = svp.get_texture()
	circle.size = Vector2(128, 128)
	peek.size = Vector2(128, 128)
	peek.visible = false
	peek_cam.enabled = true
	peek_cam.make_current()

func _process(delta: float) -> void:
	if player == null:
		return
	var off := _is_offscreen(player)
	peek.visible = off
	if off:
		peek_cam.global_position = player.global_position
		if main_cam:
			peek_cam.zoom = main_cam.zoom
			peek_cam.rotation = main_cam.rotation

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
