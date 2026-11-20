extends Node3D

var open: bool = false

# Request current locker state and connects timer if on authority
func _ready() -> void:
	request_state.rpc_id(1)

func _process(_delta: float) -> void:
	if !is_multiplayer_authority(): return
	if !open: return
	var player = Server.get_type_instance(Server.TYPE.PLAYER)
	if !player: return
	var player_pos = player.global_position
	var d2 = player_pos.distance_squared_to(global_position)
	if d2 > player.reach_squared():
		Server.alert_baldi(78)
		change_state.rpc(false)

# Client requests the current state.
@rpc("any_peer", "call_local", "reliable")
func request_state():
	if !is_multiplayer_authority():
		push_error("REQUEST STATE call should be to AUTHORITY ONLY")
		return
	var sender = multiplayer.get_remote_sender_id()
	change_state.rpc_id(sender, open, true)


# ONLY AUTHORITY can change state
@rpc("authority", "call_local", "reliable")
func change_state(state: bool, request: bool = false):
	open = state
	
	if state == false:
		$AnimationPlayer.play("close")
		if !request: $CloseSound.play()
	if state == true:
		$AnimationPlayer.play("open")
		if !request: $OpenSound.play()

# Anyone can try and toggle the locker
@rpc("any_peer", "call_local", "reliable")
func toggle_locker(id: int = -1):
	if !is_multiplayer_authority():
		push_error("OPEN DOOR REQUEST should be to AUTHORITY ONLY")
		return
	var sender_id = multiplayer.get_remote_sender_id() if id == -1 else id
	var is_player = Server.get_id_type(sender_id) == Server.TYPE.PLAYER
	if !is_player: return
	
	var sender_inst = Server.get_id_instance(sender_id)
	var locker_dist = sender_inst.global_position.distance_squared_to(global_position)
	if locker_dist > sender_inst.reach_squared():
		push_error("Unreachable locker togled")
		return
	
	if open: Server.alert_baldi(78)
	change_state.rpc(!open)
