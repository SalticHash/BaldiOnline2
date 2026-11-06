extends MeshInstance3D

func _process(_delta: float) -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam: global_position = cam.global_position
