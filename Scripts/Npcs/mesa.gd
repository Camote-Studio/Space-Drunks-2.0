extends Node2D

@export var table_height: float = 20.0

func _ready() -> void:
	add_to_group("mesa")
	print("[MESA] Agregada al grupo 'mesa'")

func get_table_height() -> float:
	# Devuelve la altura absoluta de la mesa
	return global_position.y - table_height
