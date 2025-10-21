extends StaticBody2D

#@export var cam_path: NodePath
#var cam: Camera2D
#var anchor := Vector2.ZERO
#var anchor_cam := Vector2.ZERO
#
#func _ready():
	#cam = get_node_or_null(cam_path) as Camera2D
	#if cam == null:
		#cam = get_viewport().get_camera_2d()
	#anchor = global_position
	#if cam:
		#anchor_cam = cam.global_position
#
#func _process(_dt):
	#if cam:
		#var dx = cam.global_position.x - anchor_cam.x
		#global_position.x = anchor.x + dx
