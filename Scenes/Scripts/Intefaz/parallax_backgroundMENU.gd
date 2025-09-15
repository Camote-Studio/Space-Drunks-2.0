extends ParallaxBackground

@export var speed: float = 50.0

func _process(delta):
	# Mueve el fondo hacia la derecha
	scroll_offset.x += speed * delta
