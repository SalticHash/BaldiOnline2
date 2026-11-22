extends Node

var peer = ENetMultiplayerPeer.new()

func _ready() -> void:
	$UI/Net/Options/Remote.text = "192.168.50.11"#IP.get_local_addresses()[0]
	print(IP.get_local_addresses())
	if OS.get_name() == "Android":
		OS.request_permissions()

func select_screen():
	var game = preload("res://select_screen/select_screen.tscn").instantiate()
	add_child(game)

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
	select_screen()
	#player_connected(1, %Username.text, int(%Type.text), randi_range(0, 11))


@rpc("any_peer", "call_local", "reliable")
func player_connected(id: int, username: String, type: int, skin: int = 0):
	if !is_multiplayer_authority():
		push_error("CONNECT should be called by AUTHORITY ONLY")
		return
	Server.players[id] = {"name": username, "type": type}
	playerSpawner.spawn({"id": id, "name": username, "type": type, "skin": skin})


const entities = [
	preload("res://characters/player/player.tscn"),
	preload("res://characters/baldi/baldi.tscn"),
	preload("res://characters/student/student.tscn"),
	preload("res://characters/playtime/playtime.tscn"),
]

func _spawn_player(data) -> Node:
	var type = data.get("type")
	var player = entities[type].instantiate()
	player.id = data.get("id")
	player.name = str(data.get("id"))
	player.username = data.get("name")
	if type == 2: player.skin = data.get("skin")
	return player


#################### CLIENT ######################


func _on_connect_pressed() -> void:
	get_window().size = Vector2(716, 698)
	get_window().position = Vector2(1844, 810)
	
	peer.create_client($UI/Net/Options/Remote.text, 8080)
	multiplayer.multiplayer_peer = peer
	$UI.hide()
	await multiplayer.connected_to_server
	select_screen()
	
	#player_connected.rpc_id(1, multiplayer.get_unique_id(), %Username.text, int(%Type.text), randi_range(0, 11))
	
	multiplayer.server_disconnected.connect(get_tree().quit)
