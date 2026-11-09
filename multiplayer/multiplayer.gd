extends Node

var peer = ENetMultiplayerPeer.new()

func start_game():
	var game = preload("res://level/map1.tscn").instantiate()
	add_child(game)
	playerSpawner = $World/MultiplayerSpawner
	playerSpawner.spawn_function = _spawn_player
	

#################### HOST ######################
var playerSpawner: MultiplayerSpawner
func _on_host_pressed() -> void:
	get_window().size = Vector2(716, 698)
	get_window().position = Vector2(1844, 54)
	
	peer.create_server(8080, 4)
	multiplayer.multiplayer_peer = peer
	$UI.hide()
	start_game()
	player_connected(1, %Username.text, int(%Type.text))


@rpc("any_peer", "call_local", "reliable")
func player_connected(id: int, username: String, type: int):
	if !is_multiplayer_authority():
		push_error("CONNECT should be called by AUTHORITY ONLY")
		return
	Server.players[id] = {"name": username, "type": type}
	playerSpawner.spawn({"id": id, "name": username, "type": type})


const entities = [
	preload("res://characters/player/player.tscn"),
	preload("res://characters/baldi/baldi.tscn")
]

func _spawn_player(data) -> Node:
	var player = entities[data.get("type")].instantiate()
	player.id = data.get("id")
	player.username = data.get("name")
	return player


#################### CLIENT ######################


func _on_connect_pressed() -> void:
	get_window().size = Vector2(716, 698)
	get_window().position = Vector2(1844, 810)
	
	peer.create_client("127.0.0.1", 8080)
	multiplayer.multiplayer_peer = peer
	$UI.hide()
	await multiplayer.connected_to_server
	start_game()
	
	player_connected.rpc_id(1, multiplayer.get_unique_id(), %Username.text, int(%Type.text))
	
	multiplayer.server_disconnected.connect(get_tree().quit)
