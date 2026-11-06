extends Node


var peer = ENetMultiplayerPeer.new()
func _on_host_pressed() -> void:
	peer.create_server(8080, 4)
	multiplayer.multiplayer_peer = peer
	get_tree().change_scene_to_file("res://level/map1.tscn")



func _on_connect_pressed() -> void:
	peer.create_client("127.0.0.1", 8080)
	multiplayer.multiplayer_peer = peer
	await multiplayer.connected_to_server
	get_tree().change_scene_to_file("res://level/map1.tscn")
	
