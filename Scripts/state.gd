extends Node
class_name State

var fsm: Node                # lo setea el FSM
var actor: Node2D            # normalmente el mismo boss
var body: CharacterBody2D    # CharacterBody2D del boss (lo setea el FSM)

func enter() -> void: pass
func exit() -> void: pass
func physics_update(delta: float) -> void: pass
func update(delta: float) -> void: pass
func handle_input(event: InputEvent) -> void: pass

func _get_player() -> CharacterBody2D:
	# Asegúrate de que tu Player esté en el grupo "player"
	return get_tree().get_first_node_in_group("player") as CharacterBody2D
