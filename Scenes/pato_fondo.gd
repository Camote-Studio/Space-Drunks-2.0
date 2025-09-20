extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var idle_frames: Array[int] = [0, 1, 2]  # índices de tus 3 sprites de idle
var current_order: Array[int] = []

func _ready() -> void:
	_shuffle_idle_frames()
	sprite.frame = current_order[0]
	sprite.stop()  # detener la animación automática
	set_process(true)

var frame_timer := 0.0
var frame_interval := 0.3  # cada cuánto cambia de frame
var frame_index := 0

func _process(delta: float) -> void:
	frame_timer -= delta
	if frame_timer <= 0.0:
		frame_timer = frame_interval
		frame_index += 1
		if frame_index >= current_order.size():
			_shuffle_idle_frames()
			frame_index = 0
		sprite.frame = current_order[frame_index]

func _shuffle_idle_frames() -> void:
	current_order = idle_frames.duplicate()
	current_order.shuffle()  # reorganiza aleatoriamente
