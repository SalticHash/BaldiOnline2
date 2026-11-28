extends Area3D

func _ready() -> void:
	if !is_multiplayer_authority(): return
	body_exited.connect(balloon_exited)
	for b in $Balloons.get_children():
		b.position = random_pos()

func balloon_exited(body: Node3D):
	if body.popped or body.removed or !body.can_grab: return
	if body.get_parent() != $Balloons: return
	body.pop(random_pos())

func random_pos() -> Vector3:
	var h = $Collision.shape.size / 2.0
	var pos = $Collision.position
	var local = Vector3(
		pos.x + randf_range(-h.x, h.x), 0.0,
		pos.z + randf_range(-h.z, h.z))
	return local

func pop_balloons() -> void:
	var balloons = $Balloons.get_children()
	balloons.shuffle()
	for b in balloons: b.update.rpc(&"no_interact")
	for b in balloons:
		b.pop(Vector3.ZERO, false)
		await get_tree().create_timer(randf_range(0.1, 0.3)).timeout
