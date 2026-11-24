extends Area3D

var time: float = 30.0
var rang: bool = false
func _process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	if rang:
		$Sprite.animation = "3"
		return
	$Sprite.animation = str(get_frame())
	if time <= 0.0:
		rang = true
		play_sound.rpc()
		Server.alert_baldi(112, $SP.global_position)
		return
	time -= delta

func get_frame() -> int:
	return clampi(floori(time / 60.0 * 4.0), 0, 3)

@rpc("authority", "call_local", "reliable")
func wind() -> void:
	if !is_multiplayer_authority(): return
	var sender_id = multiplayer.get_remote_sender_id()
	var is_player = Server.get_id_type(sender_id) == Server.TYPE.PLAYER
	var sender_inst = Server.get_id_instance(sender_id)
	var item_dist = sender_inst.global_position.distance_squared_to(global_position)
	if !is_player:
		push_error("Non player wind up alarm clock")
		return
	if item_dist > sender_inst.reach_squared():
		push_error("Unreachable alarm clock interacted")
		return
	
	
	var new_frame = wrapi(get_frame() - 1, 0, 4)
	var new_time = (new_frame + 1) * 15
	time = new_time
	play_sound.rpc(false)

@rpc("authority", "call_local", "reliable")
func play_sound(ring: bool = true):
	if rang: return
	if ring:
		$Ring.play()
		$Ticking.stop()
	else: $Wind.play()

func _on_ring_finished() -> void:
	if !is_multiplayer_authority(): return
	queue_free()
