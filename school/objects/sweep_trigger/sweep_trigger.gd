extends Area3D

const velocity = Vector3.ZERO
func _ready() -> void:
	if !is_multiplayer_authority(): return
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if !body.is_in_group(&"sweep"): return
	if body.sweeping:
		show()
		body.stop_sweeping()
		$PushArea.monitoring = true
	else:
		$PushArea.monitoring = false
		body.start_sweeping()
		play_sound()
		hide()


@rpc("authority", "call_local", "reliable")
func play_sound():
	$sweepin_time.play()
