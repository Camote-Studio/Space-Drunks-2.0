extends Node

var states := {}                 # name -> State
var current_state: State
var previous_state: State

@export var initial_state_name := ""   # opcional: setéalo en el inspector

func _ready() -> void:
	# Indexar únicamente hijos que sean State
	for child in get_children():
		if child is State:
			var s := child as State
			states[s.name] = s
			s.fsm = self
			s.actor = get_parent() as Node2D  # el boss (nodo padre del FSM)
			s.set_physics_process(false)

	# Elegir estado inicial
	if initial_state_name == "" and states.size() > 0:
		initial_state_name = get_child(0).name
	current_state = states.get(initial_state_name, null)
	previous_state = current_state
	if current_state:
		current_state.enter()

func transition_to(target_name: String, msg := {}) -> void:
	var next := states.get(target_name, null) as State
	if next == null or next == current_state:
		return
	# salir del actual ANTES de cambiar
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
