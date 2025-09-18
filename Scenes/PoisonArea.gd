extends Area2D

@export var damage_per_tick: float = 13.0
@export var tick_time: float = 0.5
@export var duration: float = 5.0
@onready var sprite: AnimatedSprite2D = $"../AnimatedSprite2D"
@onready var damage_timer: Timer = $"../DamageTimer"
@onready var life_timer: Timer = $"../LifeTimer"

func _ready() -> void:
	if sprite:
		sprite.play("idle")
	if damage_timer:
		damage_timer.wait_time = tick_time
		damage_timer.start()
		damage_timer.timeout.connect(_on_DamageTimer_timeout)
		print("[VENENO] DamageTimer iniciado con ", tick_time, "s")
	if life_timer:
		life_timer.wait_time = duration
		life_timer.start()
		life_timer.timeout.connect(_on_LifeTimer_timeout)
		print("[VENENO] LifeTimer iniciado con ", duration, "s")

func _on_DamageTimer_timeout() -> void:
	var bodies = get_overlapping_bodies()
	print("[VENENO] Tick de daño, cuerpos detectados: ", bodies.size())
	for body in bodies:
		if body.is_in_group("enemy_1") or body.is_in_group("enemy_2") \
		or body.is_in_group("enemy_3") or body.is_in_group("enemy_4") \
		or body.is_in_group("enemy_5") or body.is_in_group("boss"):
			if body.has_signal("damage"):
				body.emit_signal("damage", damage_per_tick)
				print("[VENENO] Daño aplicado a ", body.name)

func _on_LifeTimer_timeout() -> void:
	print("[VENENO] Se terminó la duración, eliminando área...")
	sprite.queue_free()
	queue_free()
