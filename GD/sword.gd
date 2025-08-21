extends Node2D

const PUNCH_1 = preload("res://TSCN/punch.tscn")
const PUNCH_2 = preload("res://TSCN/punch_2.tscn")
@onready var marker_2d: Marker2D = $Marker2D
@onready var marker_2d_2: Marker2D = $Marker2D2

@export var mode_random: bool = true
var next_seq := 1

func _ready() -> void:
	randomize()

func _process(delta: float) -> void:
	#look_at(get_global_mouse_position())
	#rotation_degrees = wrap(rotation_degrees,0,360)
	#if rotation_degrees > 90 and rotation_degrees < 270:
		#scale.x = -0.2
	#else:
		#scale.x = 0.2
	if Input.is_action_just_pressed("fired_2"):
		if mode_random:
			if randi() % 2 == 0:
				_spawn_punch(PUNCH_1, marker_2d, -1)
			else:
				_spawn_punch(PUNCH_2, marker_2d_2, 1)
		else:
			if next_seq == 1:
				_spawn_punch(PUNCH_1, marker_2d, -1)
				next_seq = 2
			else:
				_spawn_punch(PUNCH_2, marker_2d_2, 1)
				next_seq = 1

func _spawn_punch(scene: PackedScene, marker: Marker2D, dir: int) -> void:
	var punch = scene.instantiate()
	marker.add_child(punch)
	punch.position = Vector2.ZERO
	punch.rotation = 0.0
	var ap: AnimationPlayer = punch.get_node_or_null("AnimationPlayer")
	if ap:
		ap.play("hit")
	var area: Area2D = punch.get_node_or_null("Area2D")
	if area:
		area.monitoring = true
	var ci := _find_canvas_item(punch)
	var tween := create_tween()
	var target_pos := Vector2(0, -32) if dir < 0 else Vector2(0, 32)
	tween.tween_property(punch, "position", target_pos, 0.25)
	if ci:
		tween.parallel().tween_property(ci, "modulate:a", 0.0, 0.25)
	await tween.finished
	if area and is_instance_valid(area):
		area.monitoring = false
	if is_instance_valid(punch):
		punch.queue_free()

func _find_canvas_item(n: Node) -> CanvasItem:
	if n is CanvasItem:
		return n
	for c in n.get_children():
		var r := _find_canvas_item(c)
		if r:
			return r
	return null
