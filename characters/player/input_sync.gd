extends BaseInputSync

func _process(_delta: float) -> void:
	player.input_dir = Input.get_vector("left", "right", "forward", "backward").normalized()
	player.running = Input.is_action_pressed("run")

func _input(event: InputEvent) -> void:
	if player.locker or player.lost: return
	super(event)
