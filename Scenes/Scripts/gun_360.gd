extends Node2D

@export var bullet_scene: PackedScene = preload("res://Scenes/bullet.tscn")

var can_fire := true
@export var cooldown: float = 0.5
@onready var timer: Timer = $Timer
var pitch_variations_gun = [0.8, 1.0, 1.5]

# Offset para cuando apunta a la derecha e izquierda
@export var offset_right := Vector2(20, 20)
@export var offset_left := Vector2(-20, 20)

func _ready() -> void:
	timer.one_shot = true
	timer.wait_time = cooldown

func random_pitch_variations_gun():
	var random_pitch = pitch_variations_gun[randi() % pitch_variations_gun.size()]
	$electrogun.pitch_scale = random_pitch
	$electrogun.play()

func _process(delta: float) -> void: 
	look_at(get_global_mouse_position())
	rotation_degrees = wrap(rotation_degrees,0,360)
	if rotation_degrees > 90 and rotation_degrees < 270: 
		scale.x = -0.2 
	else: 
		scale.x = 0.2 
	if Input.is_action_just_pressed("fired") and can_fire:
		var bullet_instance = bullet_scene.instantiate()
		get_tree().root.add_child(bullet_instance) 
		bullet_instance.global_position = global_position 
		bullet_instance.rotation = rotation
		can_fire = false
		timer.start()

func _on_timer_timeout() -> void:
	can_fire = true
