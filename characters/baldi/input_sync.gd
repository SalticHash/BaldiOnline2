extends BaseInputSync

func _process(_delta: float) -> void:
	if !is_multiplayer_authority(): return

	player.slapping = Input.is_action_pressed("forward")
