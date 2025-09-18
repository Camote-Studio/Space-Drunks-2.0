extends Area2D

@export var damage: float = 25.0
@export var intensity: float = 1.0
@export var duration: float = 1.0
@export var damage_reduction: float = 0
@export var tick_rate: float = 0.2
@export var direction: Vector2 = Vector2.RIGHT

@onready var sprite: Sprite2D = $laserpng
@onready var timer_duration: Timer = $TimerDuration
@onready var timer_tick: Timer = $TimerTick
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Variables para el tamaño base del láser (ajusta estos valores en el Inspector)
@export var base_width: float = 20.0
@export var base_length: float = 100.0

var affected_enemies = []
var can_damage: bool = true

func _ready() -> void:
	# Conecta las señales de colisión
	connect("area_entered", Callable(self, "_on_area_entered"))
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("area_exited", Callable(self, "_on_area_exited"))
	connect("body_exited", Callable(self, "_on_body_exited"))

	# Configura los temporizadores
	if timer_duration:
		timer_duration.wait_time = duration
		timer_duration.start()
		timer_duration.connect("timeout", Callable(self, "_on_timer_duration_timeout"))

	if timer_tick:
		timer_tick.wait_time = tick_rate
		timer_tick.connect("timeout", Callable(self, "_on_timer_tick_timeout"))
	
	# Aplica la intensidad inicial
	_apply_intensity()
	add_to_group("player_1_bullet")

func _process(delta: float) -> void:
	# Reducir daño progresivamente (mantenemos esta lógica)
	if damage_reduction > 0:
		damage = max(0, damage - damage_reduction * delta)

func _apply_intensity() -> void:
	# Aumentar la longitud del sprite y mantener el ancho base
	var length_factor = 1.0 + (intensity * 1.5) # Aumentar la intensidad al 150%
	sprite.scale.x = base_width / sprite.texture.get_width() if sprite.texture else 1.0
	sprite.scale.y = base_length * length_factor / sprite.texture.get_height() if sprite.texture else 1.0
	
	# Ajustar el color del sprite
	#var color = Color.CYAN.lerp(Color.RED, intensity)
	#sprite.modulate = color
	
	# Escalar la forma de la colisión para que coincida
	if collision_shape:
		var shape_rect = collision_shape.shape as RectangleShape2D
		if shape_rect:
			shape_rect.size = Vector2(base_width, base_length * length_factor)
			
	damage = 15.0 + (intensity * 35.0)

func _damage_affected_enemies() -> void:
	# Aplica daño a todos los enemigos en la lista
	for enemy in affected_enemies:
		if is_instance_valid(enemy): # Valida si el nodo aún existe
			if enemy.has_signal("damage"):
				enemy.emit_signal("damage", damage)
				print("🔥 Láser hit: ", enemy.name, " por ", damage, " daño")

func start(new_duration: float, new_damage: float, new_dmg_reduction: float) -> void:
	duration = new_duration
	damage = new_damage
	damage_reduction = new_dmg_reduction
	if timer_duration:
		timer_duration.wait_time = duration
		timer_duration.start()
	if not timer_tick.is_stopped():
		timer_tick.start()

func set_intensity(new_intensity: float) -> void:
	intensity = clamp(new_intensity, 0.0, 1.0)
	_apply_intensity()

func _on_area_entered(area: Area2D) -> void:
	if area.get_parent() and not affected_enemies.has(area.get_parent()):
		_add_to_affected(area.get_parent())

func _on_body_entered(body: Node2D) -> void:
	if not affected_enemies.has(body):
		_add_to_affected(body)

func _on_area_exited(area: Area2D) -> void:
	if affected_enemies.has(area.get_parent()):
		affected_enemies.erase(area.get_parent())

func _on_body_exited(body: Node2D) -> void:
	if affected_enemies.has(body):
		affected_enemies.erase(body)

func _add_to_affected(node: Node) -> void:
	if node.is_in_group("enemy_1") or node.is_in_group("enemy_2") or node.is_in_group("enemy_3") or node.is_in_group("enemy_4") or node.is_in_group("enemy_5") or node.is_in_group("boss"):
		affected_enemies.append(node)
		if timer_tick.is_stopped():
			timer_tick.start()
		# Aplica daño instantáneo al entrar por primera vez
		_damage_enemy_once(node)

func _damage_enemy_once(enemy: Node) -> void:
	if is_instance_valid(enemy) and enemy.has_signal("damage"):
		enemy.emit_signal("damage", damage)
		print("⚡️ Láser entró en contacto con ", enemy.name, " por ", damage, " daño inicial.")

func _on_timer_tick_timeout() -> void:
	# Este temporizador se dispara cada tick_rate segundos
	_damage_affected_enemies()
	# ¡Cambiamos 'empty()' por 'is_empty()' !
	if affected_enemies.is_empty():
		timer_tick.stop()

func _on_timer_duration_timeout() -> void:
	queue_free()
