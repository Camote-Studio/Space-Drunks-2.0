extends Node2D
signal electroshock_hit(target, duration: float, factor: float)

var SPEED := 150
@export var damage_per_hit: float = 20.0

# Electroshock (la bala lo aplica directamente y además emite señal)
@export var shock_enabled := true
@export var shock_duration := 1.5
@export var shock_factor   := 0.35

# Referencia rápida al jugador (usa el grupo "players" en tu player)
@onready var player := get_tree().get_first_node_in_group("players")

# Si tu escena de bala tiene un hijo Area2D llamado "Area2D", lo conectamos por código
@onready var hit_area: Area2D = get_node_or_null("Area2D")

func _ready() -> void:
	# Aplica “power shot” si el player lo tiene
	if player and player.has_method("apply_power_to_bullet"):
		player.apply_power_to_bullet(self)

	# Asegura conexión al área de colisión
	if hit_area:
		if not hit_area.is_connected("body_entered", Callable(self, "_on_area2d_body_entered")):
			hit_area.connect("body_entered", Callable(self, "_on_area2d_body_entered"))
		if not hit_area.is_connected("area_entered", Callable(self, "_on_area2d_area_entered")):
			hit_area.connect("area_entered", Callable(self, "_on_area2d_area_entered"))

func _process(delta: float) -> void:
	position += transform.x * SPEED * delta

func _on_area2d_area_entered(a: Area2D) -> void:
	# Si golpeas un Area2D hijo del enemigo, intenta el padre tb
	if a.get_parent() and a.get_parent() is Node2D:
		_apply_hit(a.get_parent())
	else:
		_apply_hit(a)

func _on_area2d_body_entered(body: Node2D) -> void:
	_apply_hit(body)

func _apply_hit(target: Node) -> void:
	var did_hit := false
	var dmg := damage_per_hit  # SIEMPRE 20

	if target == null:
		return

	# ====== GRUPOS DE ENEMIGOS / JEFE ======
	if (target.is_in_group("enemy_1") or target.is_in_group("enemy_2")
		or target.is_in_group("enemy_3") or target.is_in_group("enemy_4")
		or target.is_in_group("enemy_5") or target.is_in_group("boss")):

		# Prioriza la señal 'damage' (tu mayoría de enemigos la exponen)
		if target.has_signal("damage"):
			target.emit_signal("damage", dmg)
			did_hit = true
		elif target.has_method("_on_damage"):
			target.call("_on_damage", dmg)
			did_hit = true

		# Electroshock: intenta directo + emite señal para quien quiera escuchar
		if did_hit and shock_enabled:
			if target.has_method("electroshock"):
				target.call("electroshock", shock_duration, shock_factor)
			emit_signal("electroshock_hit", target, shock_duration, shock_factor)

	# ====== POST-IMPACTO ======
	if did_hit:
		if player and player.has_method("gain_ability_from_attack"):
			player.gain_ability_from_attack(dmg)
		queue_free()
