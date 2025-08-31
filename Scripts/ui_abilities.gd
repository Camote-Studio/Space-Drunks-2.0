extends Control

signal request_spawn(duration: float)   # <- la señal que escuchará el spawner

@export var spawn_seconds: float = 10.0
@onready var anim: AnimationPlayer = get_node_or_null("../text_animation_abilities")
# UI_abilities.gd (fragmento)
var _buyer: Node = null  # jugador que abrió la tienda

func open_for(player: Node) -> void:
	_buyer = player
	visible = true


# Intenta varias rutas por si en tu escena cambian los nombres
func _btn(path_candidates: Array[String]) -> Button:
	for p in path_candidates:
		var b := get_node_or_null(p) as Button
		if b: return b
	return null

var chicken_btn: Button
var jet_btn: Button
var gun_btn: Button

func _ready() -> void:
	print("[UI] READY en ", get_path())
	# Capturar click y que NO pase al juego por debajo
	mouse_filter = Control.MOUSE_FILTER_STOP
	var cr := get_node_or_null("ColorRect") as Control
	if cr:
		cr.mouse_filter = Control.MOUSE_FILTER_STOP

	# buscar botones (ajusta si tu jerarquía cambia)
	chicken_btn = _btn(["ColorRect/Button", "Button", "%ChickenBtn"])
	jet_btn     = _btn(["ColorRect/Button2", "%JetBtn"])
	gun_btn     = _btn(["ColorRect/Button3", "%GunBtn"])

	print("[UI] chicken_btn=", chicken_btn, " jet_btn=", jet_btn, " gun_btn=", gun_btn)

	# autoconexión con logs
	if chicken_btn:
		if not chicken_btn.is_connected("pressed", Callable(self, "_on_chicken_pressed")):
			chicken_btn.connect("pressed", Callable(self, "_on_chicken_pressed"))
		print("[UI] conectado botón CHICKEN")
	else:
		push_warning("[UI] No encontré chicken_btn en las rutas dadas")

	if jet_btn:
		if not jet_btn.is_connected("pressed", Callable(self, "_on_jet_pressed")):
			jet_btn.connect("pressed", Callable(self, "_on_jet_pressed"))
		print("[UI] conectado botón JET")
	else:
		push_warning("[UI] No encontré jet_btn")

	if gun_btn:
		if not gun_btn.is_connected("pressed", Callable(self, "_on_gun_pressed")):
			gun_btn.connect("pressed", Callable(self, "_on_gun_pressed"))
		print("[UI] conectado botón GUN")
	else:
		push_warning("[UI] No encontré gun_btn")

	visible = false

func open() -> void:
	print("[UI] open() → visible true")
	visible = true

func _close_ui() -> void:
	print("[UI] close() → visible false")
	visible = false

func _play_anim(name: String) -> void:
	if anim:
		anim.stop()
		anim.play(name)
		print("[UI] Animación: ", name)
	else:
		push_warning("[UI] No hay AnimationPlayer para reproducir ", name)

func _on_chicken_pressed() -> void:
	print("[UI] Chicken PRESSED → request_spawn(", spawn_seconds, ")")
	emit_signal("request_spawn", spawn_seconds)
	_play_anim("chicken")
	_close_ui()

func _on_gun_pressed() -> void:
	var p1 := get_tree().get_first_node_in_group("player") as Node
	if p1 and p1.has_method("activate_electro_for"):
		p1.activate_electro_for() # 15–20 s aleatorio
		print("[UI] ElectroGun solicitada")
	visible = false
	_play_anim("gun")
	_close_ui()


func _on_gun_360_pressed() -> void:
	print("[UI] Jet PRESSED → request_spawn(", spawn_seconds, ")")
	emit_signal("request_spawn", spawn_seconds)
	_play_anim("jet")
	_close_ui()
