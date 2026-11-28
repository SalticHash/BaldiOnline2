extends Area3D

@rpc("authority", "call_local", "reliable")
func enter_locker():
	$Sound.play()
	if is_multiplayer_authority():
		Server.alert_baldi(78, null, $SP.global_position)
