extends Area2D

@export var damage_amount: float = 20.0
@export var hit_cooldown: float = 0.4
@export var destroy_on_hit: bool = false
@export var life_time: float = 5.0 

@onready var life_timer: Timer = $LifeTimer 
var _last_hit_time := {}

func _ready() -> void:
	$life_timer.start()
	monitoring = true
	monitorable = true

	# señales de área
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))
	if not is_connected("area_entered", Callable(self, "_on_area_entered")):
		connect("area_entered", Callable(self, "_on_area_entered"))

	# programa el autodespawn
	if life_time > 0.0 and life_timer:
		life_timer.one_shot = true
		life_timer.start(life_time)
		# si no conectaste en el editor:
		if not life_timer.is_connected("timeout", Callable(self, "_on_life_timer_timeout")):
			life_timer.connect("timeout", Callable(self, "_on_life_timer_timeout"))

func _on_life_timer_timeout() -> void:
	print("desaparezco")
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	_try_hit(body)

func _on_area_entered(a: Area2D) -> void:
	_try_hit(a)
	if a.get_parent() and a.get_parent() is Node2D:
		_try_hit(a.get_parent())

func _try_hit(target: Node) -> void:
	if not _is_damageable(target):
		return

	var id := target.get_instance_id()
	var now := Time.get_unix_time_from_system()
	if _last_hit_time.has(id) and now - _last_hit_time[id] < hit_cooldown:
		return
	_last_hit_time[id] = now

	if target.has_method("_on_damage"):
		target.call("_on_damage", damage_amount)
	elif target.has_signal("damage"):
		target.emit_signal("damage", damage_amount)

	if destroy_on_hit:
		set_deferred("monitoring", false)
		queue_free()

func _is_damageable(n: Node) -> bool:
	if n.is_in_group("player") or n.is_in_group("player_2"):
		return true
	if n.is_in_group("boss"):
		return true
	for g in ["enemy_1","enemy_2","enemy_3","enemy_4","enemy_5"]:
		if n.is_in_group(g):
			return true
	return false
