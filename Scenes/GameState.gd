extends Node

# Diccionario para guardar las monedas por jugador
var coins_per_player: Dictionary = {}

func set_coins(player_id: String, amount: int) -> void:
	coins_per_player[player_id] = amount

func add_coins(player_id: String, amount: int) -> void:
	coins_per_player[player_id] = get_coins(player_id) + amount

func get_coins(player_id: String) -> int:
	return coins_per_player.get(player_id, 0)
