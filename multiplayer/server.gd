extends Node
var players: Dictionary = {}

func get_type_id(type) -> int:
	for player_id in players.keys():
		var player = players.get(player_id)
		if player.get("type") == type:
			return player_id
	return -1
