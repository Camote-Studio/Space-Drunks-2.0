extends Node

var states := {}                 # name -> State
var current_state: State
var previous_state: State

@export var initial_state_name := ""   # opcional: setéalo en el inspector

func _ready() -> void:
	set_process(true)
	set_physics_process(true)

	# Resolver el CharacterBody2D ancestro (el boss)
	var boss_body: CharacterBody2D = null
	var n: Node = self
	while n:
		if n is CharacterBody2D:
			boss_body = n as CharacterBody2D
			break
		n = n.get_parent()

	if boss_body == null:
		push_error("FSM: no se encontró un CharacterBody2D ancestro. Verifica la jerarquía.")
		return

	# Indexar estados y configurar referencias
	for child in get_children():
		if child is State:
			var s := child as State
			states[s.name] = s
			s.fsm = self
			s.actor = get_parent() as Node2D   # normalmente el boss o su contenedor directo
			s.body = boss_body                 # <- aquí inyectamos el CharacterBody2D
			# los estados no procesan por sí solos; el FSM los llama
			s.set_physics_process(false)
			s.set_process(false)

	# Elegir estado inicial seguro
	if initial_state_name == "" and states.size() > 0:
		initial_state_name = states.keys()[0]

	current_state = states.get(initial_state_name, null)
	previous_state = current_state
	if current_state:
		current_state.enter()
	else:
		push_warning("FSM: estado inicial inválido (revisa 'initial_state_name' o hijos State)")

func transition_to(target_name: String, msg := {}) -> void:
	var next := states.get(target_name, null) as State
	if next == null or next == current_state:
		return
	if current_state:
		current_state.exit()
	previous_state = current_state
	current_state = next
	current_state.enter()

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)
