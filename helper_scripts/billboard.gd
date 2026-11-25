extends Sprite3D


func _process(_delta: float) -> void:
	var camera = get_viewport().get_camera_3d()
	if !camera: return
	
	var target_pos = camera.global_position
	target_pos.y = global_position.y
	look_at(target_pos, Vector3.UP, true)
