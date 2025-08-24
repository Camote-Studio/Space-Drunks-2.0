extends Node2D

const PUNCH_1 = preload("res://Scenes/punch.tscn")
const PUNCH_2 = preload("res://Scenes/punch_2.tscn")
@onready var marker_2d: Marker2D = $Marker2D
@onready var marker_2d_2: Marker2D = $Marker2D2
@export var mode_random: bool = true
var next_seq := 1

func _ready() -> void:
	randomize()

func _process(delta: float) -> void:
	# Obtenemos la dirección del sprite del jugador.
	var player_sprite_is_flipped = get_parent().get_node("AnimatedSprite2D").flip_h

	# Ajustamos la posición de los Marker2D según la dirección
	if player_sprite_is_flipped:
		marker_2d.position.x = -abs(marker_2d.position.x)
		marker_2d_2.position.x = -abs(marker_2d_2.position.x)
	else:
		marker_2d.position.x = abs(marker_2d.position.x)
		marker_2d_2.position.x = abs(marker_2d_2.position.x)

	if Input.is_action_just_pressed("fired_2"):
		var attack_direction = -1 if player_sprite_is_flipped else 1

		if mode_random:
			if randi() % 2 == 0:
				_spawn_punch(PUNCH_1, marker_2d, attack_direction)
			else:
				_spawn_punch(PUNCH_2, marker_2d_2, attack_direction)
		else:
			if next_seq == 1:
				_spawn_punch(PUNCH_1, marker_2d, attack_direction)
				next_seq = 2
			else:
				_spawn_punch(PUNCH_2, marker_2d_2, attack_direction)
				next_seq = 1


func _spawn_punch(scene: PackedScene, marker: Marker2D, dir: int) -> void:
	var punch = scene.instantiate()
	marker.add_child(punch)
	punch.position = Vector2.ZERO
	punch.rotation = 0.0

	# Volteamos el sprite del golpe para que coincida con el jugador.
	# Asegúrate de que tu escena de golpe ('punch.tscn' y 'punch_2.tscn') tenga un Sprite2D
	var punch_sprite = punch.get_node_or_null("Sprite2D")
	if punch_sprite:
		punch_sprite.flip_h = dir < 0

	var ap: AnimationPlayer = punch.get_node_or_null("AnimationPlayer")
	if ap:
		ap.play("hit")

	var area: Area2D = punch.get_node_or_null("Area2D")
	if area:
		area.monitoring = true

	var ci := _find_canvas_item(punch)
	var tween := create_tween()

	# Ajustamos la posición objetivo para que se mueva horizontalmente.
	# Si dir es -1, se mueve hacia la izquierda; si es 1, a la derecha.
	# Esto es solo si quieres que el golpe se mueva del lugar de origen.
	var target_pos = Vector2(32 * dir, 0) # Ejemplo de movimiento horizontal

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
