extends Area3D

func _ready() -> void:
	if !is_multiplayer_authority(): return
	body_exited.connect(balloon_exited)
	for b in $Balloons.get_children():
		b.position = random_pos()

func balloon_exited(body: Node3D):
	if body.popped: return
	body.pop(random_pos())

func random_pos() -> Vector3:
	var h = $Collision.shape.size / 2.0
	var pos = $Collision.position
	var local = Vector3(
		pos.x + randf_range(-h.x, h.x), 0.0,
		pos.z + randf_range(-h.z, h.z))
	return local

func pop_balloons() -> void:
	for b in $Balloons.get_children(): b.update.rpc(&"no_interact")
	await get_tree().create_timer(0.5).timeout
	for b in $Balloons.get_children():
		await get_tree().create_timer(0.1).timeout
		b.pop(Vector3.ZERO, false)
