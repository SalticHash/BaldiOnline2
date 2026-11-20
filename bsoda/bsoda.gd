extends StaticBody3D

var speed = 2
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var direction := (transform.basis * Vector3.FORWARD).normalized()
	position += direction * speed * delta

func _on_despawn_timeout() -> void:
	if !is_multiplayer_authority(): return
	queue_free()
