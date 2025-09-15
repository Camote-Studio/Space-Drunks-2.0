extends Area2D

@export var lifetime := 2.5
@export var dps := 12.0
@export var tick := 0.25

var _tick_timer: Timer
var _life_timer: Timer
var _inside := {}   # cuerpos dentro: {node_id: Node}

func _ready() -> void:
	monitoring = true
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))
	if not is_connected("body_exited", Callable(self, "_on_body_exited")):
		connect("body_exited", Callable(self, "_on_body_exited"))

	_tick_timer = Timer.new()
	_tick_timer.one_shot = false
	_tick_timer.wait_time = tick
	add_child(_tick_timer)
	_tick_timer.connect("timeout", Callable(self, "_on_tick"))
	_tick_timer.start()

	_life_timer = Timer.new()
	_life_timer.one_shot = true
	_life_timer.wait_time = lifetime
	add_child(_life_timer)
	_life_timer.connect("timeout", Callable(self, "_on_life_timeout"))
	_life_timer.start()

func setup(p_life: float, p_dps: float, p_tick: float) -> void:
	lifetime = p_life
	dps = p_dps
	tick = p_tick
	if _tick_timer:
		_tick_timer.wait_time = tick
	if _life_timer:
		_life_timer.wait_time = lifetime

func _on_body_entered(body: Node) -> void:
	_inside[body.get_instance_id()] = body

func _on_body_exited(body: Node) -> void:
	_inside.erase(body.get_instance_id())

func _on_tick() -> void:
	var dmg := dps * tick
	for id in _inside.keys():
		var n: Node = _inside[id]
		# daño al jugador (o a quien tenga la señal "damage")
		if n and n.has_signal("damage"):
			n.emit_signal("damage", dmg)

func _on_life_timeout() -> void:
	queue_free()
