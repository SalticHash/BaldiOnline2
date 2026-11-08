extends BaseInputSync

func _process(_delta: float) -> void:
	if !is_multiplayer_authority(): return
		# TESTING code
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
		
	player.slapping = Input.is_action_pressed("forward")
