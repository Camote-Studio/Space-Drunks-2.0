extends Node

# Diccionario para guardar las monedas por jugador
var coins_per_player: Dictionary = {}
var player_vida: Dictionary = {}
func set_vida(player_id:String , vida:int) -> void:
	player_vida[player_id] = vida

func get_vida(player_id:String) -> int:
	return player_vida.get(player_id, 0)

func set_coins(player_id: String, amount: int) -> void:
	coins_per_player[player_id] = amount

func add_coins(player_id: String, amount: int) -> void:
	coins_per_player[player_id] = get_coins(player_id) + amount

func get_coins(player_id: String) -> int:
	return coins_per_player.get(player_id, 0)
