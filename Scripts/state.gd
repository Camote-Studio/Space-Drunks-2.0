extends Node
class_name State

var fsm: Node
var actor: Node2D

func enter(msg := {}) -> void:
	set_physics_process(true)

func exit() -> void:
	set_physics_process(false)

func handle_input(_event: InputEvent) -> void: pass
func physics_update(delta: float) -> void: transition(delta)
func update(_delta: float) -> void: pass
func transition(_delta: float) -> void: pass

# Helpers
func _get_player() -> Node2D:
	return actor.get_tree().get_first_node_in_group("player") as Node2D

func _dir_to_player() -> Vector2:
	var p := _get_player()
	if p == null: return Vector2.RIGHT
	return (p.global_position - actor.global_position).normalized()
