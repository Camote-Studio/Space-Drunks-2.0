extends Area2D

@onready var mensaje_portal = $mensaje_portal
var locked: bool = false
var mostrando_mensaje: bool = false

func _ready():
	mensaje_portal.visible = false   # Oculto al inicio

func lock_portal():
	locked = true

func unlock_portal():
	locked = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("player_2"):
		if locked:
			# Mostrar mensaje si el portal está cerrado
			if not mostrando_mensaje:
				mostrar_mensaje_portal()
			return
		
		# Cambiar de escena SOLO si no está bloqueado
		get_tree().change_scene_to_file("res://Scenes/Level1_F2.tscn")

func mostrar_mensaje_portal():
	mostrando_mensaje = true
	mensaje_portal.visible = true

	# Parpadeo con Tween
	var tween = create_tween()
	tween.set_loops(6) # 6 parpadeos
	tween.tween_property(mensaje_portal, "modulate:a", 0.0, 0.3)
	tween.tween_property(mensaje_portal, "modulate:a", 1.0, 0.3)

	# Al terminar el parpadeo, ocultamos el mensaje
	tween.finished.connect(func():
		mensaje_portal.visible = false
		mostrando_mensaje = false
	)
