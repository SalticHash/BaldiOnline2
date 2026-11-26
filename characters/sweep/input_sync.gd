extends BaseInputSync

func _process(_delta: float) -> void:
	player.input_dir = Input.get_vector("left", "right", "forward", "backward").normalized()
