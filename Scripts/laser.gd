# laser.gd: Modificado para comportarse como un haz estático
extends Area2D

# --- Propiedades ---
@export var base_damage: float = 25.0
@export var base_width: float = 30.0 
@export var intensity: float = 1.0
@export var pierce_count: int = 3
@export var max_range: float = 800.0 # Ahora representa la LONGITUD del haz

# La velocidad y la dirección ya no son necesarias
# @export var speed: float = 1200.0

# --- Componentes ---
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

# --- Variables de Estado ---
var current_damage: float = 25.0
var hit_enemies: Array = []
var pierced_count: int = 0
var original_scale: Vector2

# La dirección y la distancia recorrida ya no son necesarias
# var direction: Vector2 = Vector2.RIGHT
# var distance_traveled: float = 0.0

func _ready() -> void:
	if sprite:
		original_scale = sprite.scale
	
	connect("area_entered", Callable(self, "_on_area_entered"))
	connect("body_entered", Callable(self, "_on_body_entered"))
	
	_apply_intensity()
	add_to_group("player_1_bullet")

func _physics_process(delta: float) -> void:
	# ELIMINADO: El láser ya no se mueve por sí mismo.
	# Su posición y rotación son controladas por su nodo padre (el arma).
	pass

# NUEVA FUNCIÓN: Configura la longitud visual y de colisión del haz.
func setup_beam(length: float) -> void:
	max_range = length
	if not sprite or not collision or not collision.shape is RectangleShape2D:
		push_warning("El láser no tiene Sprite2D o su CollisionShape2D no es un rectángulo.")
		return
	
	# Asumimos que el sprite y la colisión en la escena original apuntan hacia la derecha (eje X+).
	var shape = collision.shape as RectangleShape2D
	
	# 1. Ajustar la longitud de la colisión
	shape.size.x = length
	
	# 2. Ajustar la longitud visual del sprite
	# Esto funciona mejor si la propiedad "Texture > Repeat" del sprite está en "Enabled" o "Tile".
	if sprite.texture:
		var texture_width = sprite.texture.get_width()
		sprite.scale.x = original_scale.x * (length / texture_width)

	# 3. Mover el centro del sprite y la colisión para que el origen (0,0) sea el inicio del haz.
	# De esta forma, el láser nacerá desde la punta del arma, no desde su centro.
	var offset = length / 2.0
	sprite.position.x = offset
	collision.position.x = offset
	
# La función start sigue siendo útil para el timer de duración y la reducción de daño.
func start(duration: float = 2.0, damage: float = 25.0, damage_reduction: float = 5.0) -> void:
	base_damage = damage
	current_damage = damage
	
	# El timer de duración máxima sigue funcionando igual.
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "queue_free"))
	add_child(timer)
	timer.start()
	
	var damage_timer = Timer.new()
	damage_timer.wait_time = 1.0
	damage_timer.connect("timeout", _reduce_damage)
	add_child(damage_timer)
	damage_timer.start()

# --- El resto del script (manejo de daño, intensidad, colisiones) permanece igual ---
# ... (las funciones _apply_intensity, _on_area_entered, _handle_enemy_hit, etc., no necesitan cambios)
# Permite cambiar la intensidad del láser desde otro script.
func set_intensity(new_intensity: float) -> void:
	# Limita el nuevo valor de intensidad entre 0.0 y 1.0.
	intensity = clamp(new_intensity, 0.0, 1.0)
	# Vuelve a aplicar los efectos visuales y de daño con la nueva intensidad.
	_apply_intensity()

# Permite cambiar el daño del láser.
func set_damage(new_damage: float) -> void:
	base_damage = new_damage
	current_damage = new_damage

# Aplica los cambios visuales y de daño basados en la variable `intensity`.
func _apply_intensity() -> void:
	# Si el sprite no existe, no hace nada para evitar errores.
	if not sprite or not collision or not collision.shape is RectangleShape2D:
		return
	
	# Calcula un factor de escala entre 0.5 (intensidad=0) y 1.5 (intensidad=1).
	var scale_factor = 0.5 + (intensity * 1.0)
	# Aplica la escala solo en el eje Y, manteniendo la X original.
	sprite.scale = Vector2(original_scale.x, original_scale.y * scale_factor)
	
	# Interpola el color entre CIAN (intensidad=0) y ROJO (intensidad=1).
	var color = Color.CYAN.lerp(Color.RED, intensity)
	# Aplica el color al sprite. `modulate` multiplica el color del sprite por este nuevo color.
	sprite.modulate = color
	
	# Si la colisión existe y es un rectángulo...
	if collision and collision.shape is RectangleShape2D:
		var shape = collision.shape as RectangleShape2D
		# ...ajusta su altura según el `scale_factor` (¡AQUÍ ESTÁ EL VALOR HARDCODEADO!).
		shape.size.y = 10.0 * scale_factor
	
	# Ajusta el daño actual: daño base + un extra por intensidad.
	current_damage = base_damage + (intensity * 35.0)

# --- Colisiones ---

# Se llama automáticamente cuando otro Area2D entra en la colisión de este láser.
func _on_area_entered(area: Area2D) -> void:
	# Asume que el nodo principal del enemigo es el padre del área de colisión.
	var enemy = area.get_parent()
	_handle_enemy_hit(enemy) # Llama a la función genérica para manejar el golpe.

# Se llama cuando un PhysicsBody2D entra en la colisión.
func _on_body_entered(body: Node2D) -> void:
	# Llama a la misma función para manejar el golpe.
	_handle_enemy_hit(body)

# Lógica central para cuando el láser golpea a algo.
func _handle_enemy_hit(enemy: Node) -> void:
	# Ignora el golpe si el enemigo no es válido o si ya ha sido golpeado por este láser.
	if not enemy or enemy in hit_enemies:
		return
	
	# Si el nodo golpeado no está en un grupo de enemigos, lo ignora.
	if not _is_enemy(enemy):
		return
	
	# Lo añade a la lista de golpeados para no volver a dañarlo.
	hit_enemies.append(enemy)
	# Incrementa el contador de enemigos atravesados.
	pierced_count += 1
	
	# Si el enemigo tiene una señal llamada "damage", la emite para que el enemigo procese el daño.
	if enemy.has_signal("damage"):
		enemy.emit_signal("damage", current_damage)
	
	# Imprime en la consola un mensaje de depuración.
	print("Laser hit:", enemy.name, "- Damage:", current_damage)
	
	# Si el número de enemigos atravesados alcanza el límite...
	if pierced_count >= pierce_count:
		# ...el láser se destruye.
		queue_free()

# Comprueba si un nodo pertenece a alguno de los grupos de enemigos definidos.
func _is_enemy(node: Node) -> bool:
	return (node.is_in_group("enemy_1") or
			node.is_in_group("enemy_2") or
			node.is_in_group("enemy_3") or
			node.is_in_group("enemy_4") or
			node.is_in_group("enemy_5") or
			node.is_in_group("boss"))

# Se llama cada segundo (por el timer `damage_timer`) para reducir el daño.
func _reduce_damage() -> void:
	# Reduce el `current_damage` en 5, pero nunca por debajo del 30% del daño base.
	current_damage = max(base_damage * 0.3, current_damage - 5.0)
	
	# Si el sprite existe, ajusta su transparencia para indicar que el láser se está "debilitando".
	if sprite:
		# Calcula qué porcentaje del daño base representa el daño actual.
		var alpha = current_damage / base_damage
		# Aplica ese porcentaje al canal alfa (transparencia) del color, con un mínimo de 0.4.
		sprite.modulate.a = clamp(alpha, 0.4, 1.0)

# --- Funciones adicionales simples ---
# Permiten modificar propiedades del láser de forma segura desde otros scripts.

func set_piercing(amount: int) -> void:
	# Establece la cantidad de perforación, asegurando que sea al menos 1.
	pierce_count = max(1, amount)

func set_range(range_value: float) -> void:
	# Establece el rango máximo, asegurando que sea al menos 100.
	max_range = max(100.0, range_value)

#func set_speed(speed_value: float) -> void:
	# Establece la velocidad, asegurando que sea al menos 200.
	#speed = max(200.0, speed_value)
