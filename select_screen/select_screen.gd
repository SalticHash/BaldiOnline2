extends Control

const characters: Dictionary[int, String] = {
	-1: "None",
	0: "Player",
	1: "Baldi",
	2: "Student",
	3: "Playtime"
}

const icons = {
	-1: "res://select_screen/thumb/none.png",
	0: "res://select_screen/thumb/player.png",
	1: "res://select_screen/thumb/baldi.png",
	3: "res://select_screen/thumb/playtime.png",
}
var players: Dictionary[int, Dictionary]

@rpc("authority", "call_local", "reliable")
func player_list_changed(up_players: Dictionary[int, Dictionary]):
	%PlayerList.clear()
	for player in up_players.values():
		var id = player.get("id")
		var username = player.get("username")
		var character = player.get("type")
		var skin = player.get("skin")
		var text = "%s (%s)" % [username, characters[character]]
		if id == 1: text += " (HOST)"
		var icon: Texture2D = null
		if character == 2:
			icon = load("res://select_screen/thumb/students/%d.png" % skin)
		else:
			icon = load(icons[character])
		%PlayerList.add_item(text, icon, false)

func _ready() -> void:
	%StudentSkin.select(0)
	%Username.text = "Player #" + str(multiplayer.get_unique_id())
	connected.rpc_id(1)
	if is_multiplayer_authority():
		%Start.show()

func _on_character_item_selected(index: int) -> void:
	%StudentSkin.visible = index == 2
	%Deselect.disabled = false
	selected_character.rpc_id(1, index, get_student_skin() if index == 2 else -1)

func _on_deselect_pressed() -> void:
	%Deselect.disabled = true
	
	%Character.deselect_all()
	%StudentSkin.hide()
	selected_character.rpc_id(1, -1)

func _on_student_skin_item_selected(index: int) -> void:
	var icon = %StudentSkin.get_item_icon(index)
	%Character.set_item_icon(2, icon)
	selected_character.rpc_id(1, 2, get_student_skin())

func get_student_skin() -> int:
	var idx = %StudentSkin.get_selected_items()[0]
	var i: Texture2D = %StudentSkin.get_item_icon(idx)
	var p: String = i.resource_path
	var skin = p.replace("res://select_screen/thumb/students/", "").left(-4)
	return int(skin)

func _on_username_text_submitted(new_text: String) -> void:
	selected_name.rpc_id(1, new_text)


@rpc("any_peer", "call_local", "reliable")
func connected():
	if !is_multiplayer_authority(): return
	var sender_id = multiplayer.get_remote_sender_id()
	players[sender_id] = {
		"id": sender_id,
		"username": "Player #" + str(sender_id),
		"type": -1,
		"skin": -1
	}
	player_list_changed.rpc(players)
	


@rpc("any_peer", "call_local", "reliable")
func selected_name(username: String):
	if !is_multiplayer_authority(): return
	var sender_id = multiplayer.get_remote_sender_id()
	players[sender_id]["username"] = username
	player_list_changed.rpc(players)

@rpc("any_peer", "call_local", "reliable")
func selected_character(type: int, skin: int = -1):
	if !is_multiplayer_authority(): return
	var sender_id = multiplayer.get_remote_sender_id()
	players[sender_id]["type"] = type
	players[sender_id]["skin"] = skin
	player_list_changed.rpc(players)

@rpc("authority", "call_local", "reliable")
func started() -> void:
	hide()
	get_parent().start_game()

func _on_start_pressed() -> void:
	if !is_multiplayer_authority(): return
	started.rpc()
	Server.players = players
	for player in players.values():
		get_parent().playerSpawner.spawn(player)
