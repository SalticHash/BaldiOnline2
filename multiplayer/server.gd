extends Node
var players: Dictionary = {}

var exits: int = 0
enum TYPE {
	PLAYER,
	BALDI
}
func get_type_id(type: int) -> int:
	for player_id in players.keys():
		var player = players.get(player_id)
		if player.get("type") == type:
			return player_id
	return -1

func get_id_type(id: int) -> int:
	return players.get(id).get("type")
	
func get_type_instance(type: int) -> Node3D:
	var id = get_type_id(type)
	return get_id_instance(id)

func get_id_instance(id: int) -> Node3D:
	if id == -1:
		push_warning("Invalid ID for get_id_instance")
		return null
	return get_node("/root/Game/World/Players").get_node(str(id))

func rpc_type(type: int, method: StringName, ...args: Array) -> void:
	var id = get_type_id(type)
	if id == -1:
		push_warning("Invalid ID for rpc_type")
		return
	var inst = get_id_instance(id)
	inst.callv("rpc_id", [id, method] + args)
	

func alert_baldi(noise: int):
	var p = get_type_instance(TYPE.PLAYER).global_position
	
	rpc_type(Server.TYPE.BALDI, "spawn_highlight", p, noise)
