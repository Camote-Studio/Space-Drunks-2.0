extends Area2D

@onready var mensaje_portal = $mensaje_portal
@onready var vortex_sprite: AnimatedSprite2D = $"../UI2/Vortex"

@export var next_scene_path: String = "res://Scenes/Level1_F2.tscn"

var locked: bool = false
var mostrando_mensaje: bool = false
var _is_transitioning: bool = false

func _ready() -> void:
	mensaje_portal.visible = false
	if vortex_sprite:
		vortex_sprite.visible = false
		vortex_sprite.stop()
		vortex_sprite.frame = 0

func _on_body_entered(body: Node2D) -> void:
	if not (body.is_in_group("player") or body.is_in_group("player_2")):
		return
	if locked:
		if not mostrando_mensaje:
			mostrar_mensaje_portal()
		return
	if _is_transitioning:
		return

	_is_transitioning = true
	set_deferred("monitoring", false)
	vortex_sprite.play("default")
	ir_a_siguiente_escena()
	#await reproducir_vortex_y_cambiar()

func mostrar_mensaje_portal() -> void:
	mostrando_mensaje = true
	mensaje_portal.visible = true
	var tween = create_tween()
	tween.set_loops(6)
	tween.tween_property(mensaje_portal, "modulate:a", 0.0, 0.3)
	tween.tween_property(mensaje_portal, "modulate:a", 1.0, 0.3)
	tween.finished.connect(func():
		mensaje_portal.visible = false
		mostrando_mensaje = false
	)

#func reproducir_vortex_y_cambiar() -> void:
	#if not vortex_sprite:
	#	await get_tree().create_timer(0.2).timeout
	#	ir_a_siguiente_escena()
	#	return

	#vortex_sprite.visible = true
	#vortex_sprite.stop()
	#vortex_sprite.frame = 0
	#vortex_sprite.play("default")
	# Espera la duración estimada de la animación (frames / fps)
	#var frames = vortex_sprite.sprite_frames.get_frame_count(vortex_sprite.animation)
	#var fps = vortex_sprite.sprite_frames.get_animation_speed(vortex_sprite.animation)
	#var duracion = float(frames) / max(1.0, fps)

	#await get_tree().create_timer(duracion + 0.1).timeout
	#ir_a_siguiente_escena()

func ir_a_siguiente_escena() -> void:
	
	get_tree().change_scene_to_file(next_scene_path)
	_is_transitioning = false
	set_deferred("monitoring", true)
