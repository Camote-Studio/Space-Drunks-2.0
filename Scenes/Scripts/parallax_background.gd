extends ParallaxBackground

@export var cam_path: NodePath
@export var velocidad_scroll: float = 0.0
@export var follow_y: bool = false

var cam: Camera2D
var _auto_x := 0.0
var _anchor_cam := Vector2.ZERO
var _anchor_base := Vector2.ZERO

func _ready() -> void:
	cam = get_node_or_null(cam_path) as Camera2D
	if cam == null:
		cam = get_viewport().get_camera_2d()
	_anchor_base = scroll_base_offset
	if cam:
		_anchor_cam = cam.global_position
	_setup_mirroring()

func _process(delta: float) -> void:
	_auto_x += velocidad_scroll * delta
	var dx := 0.0
	var dy := 0.0
	if cam:
		dx = cam.global_position.x - _anchor_cam.x
		if follow_y:
			dy = cam.global_position.y - _anchor_cam.y
	scroll_base_offset = Vector2(_anchor_base.x + _auto_x + dx, _anchor_base.y + dy)

func _setup_mirroring() -> void:
	for c in get_children():
		if c is ParallaxLayer:
			var s := c.get_node_or_null("Sprite2D") as Sprite2D
			if s and s.texture:
				var w := float(s.texture.get_size().x) * s.scale.x
				(c as ParallaxLayer).motion_mirroring.x = w
