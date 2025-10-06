extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var start_pos: Vector2
var target_pos: Vector2
var speed: float = 130.0       # velocidad hacia adelante
var return_speed: float = 130.0  # velocidad al regresar
var state: String = "idle_forward"
var timer: Timer

func _ready() -> void:
	start_pos = global_position
	target_pos = start_pos + Vector2(350, 0)

	# Creamos el timer por código
	timer = Timer.new()
	timer.one_shot = true
	add_child(timer)

	sprite.play("idle")
	sprite.flip_h = false  # empieza mirando a la derecha

func _process(delta: float) -> void:
	match state:
		"idle_forward":
			# mover hacia la derecha
			global_position.x += speed * delta
			if global_position.x >= target_pos.x:
				global_position.x = target_pos.x
				_start_preocupado_phase("right")

		"preocupado_right":
			# el personaje tiembla arriba/abajo
			var offset = sin(Time.get_ticks_msec() / 100.0) * 5
			global_position.y = start_pos.y + offset
			# cuando acabe el timer, vuelve
			if not timer.is_stopped():
				pass
			else:
				_start_idle_return()

		"idle_return":
			# mover de regreso a la izquierda
			global_position.x -= return_speed * delta
			if global_position.x <= start_pos.x:
				global_position = start_pos
				_start_preocupado_phase("left")

		"preocupado_left":
			# el personaje tiembla arriba/abajo también al llegar al inicio
			var offset = sin(Time.get_ticks_msec() / 100.0) * 5
			global_position.y = start_pos.y + offset
			if not timer.is_stopped():
				pass
			else:
				_start_idle_phase()

func _start_idle_phase() -> void:
	state = "idle_forward"
	sprite.play("idle")
	sprite.flip_h = false  # mira hacia la derecha

func _start_preocupado_phase(direction: String) -> void:
	state = "preocupado_%s" % direction
	sprite.play("preocupado")
	timer.start(2.0)  # dura 2 segundos

func _start_idle_return() -> void:
	state = "idle_return"
	sprite.play("idle")
	sprite.flip_h = true  # mira hacia la izquierda
