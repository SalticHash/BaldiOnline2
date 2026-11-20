extends BaseInputSync

func _process(_delta: float) -> void:
	# TESTING code
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		player.input_dir = Vector2.ZERO
		return
	player.input_dir = Input.get_vector("left", "right", "forward", "backward")
	player.running = Input.is_action_pressed("run")

func _input(event: InputEvent) -> void:
	if player.locker or player.lost: return
	super(event)
