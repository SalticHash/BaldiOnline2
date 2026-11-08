extends BaseController

var input_dir: Vector2 = Vector2.ZERO
func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return

	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity = direction * SPEED * delta

	move_and_slide()
