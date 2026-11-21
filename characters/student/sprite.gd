extends AnimatedSprite3D

var walking: bool = false
var yay: bool = false
var skin: int = 0
func _process(_delta: float) -> void:
	if yay:
		play("%d_yay" % skin)
		return
	
	var cam = get_viewport().get_camera_3d()
	if !cam: return
	var cam_pos = cam.global_position
	var direction = global_position - cam_pos
	var current_cam_angle = atan2(direction.x, direction.z)
	var effective_angle = -global_rotation.y + current_cam_angle
	var angle: int = wrapi(snappedi(rad_to_deg(effective_angle), 30), 0, 360)
	
	var target_anim = "%d_%d" % [skin, angle]
	
	if walking:
		if animation != target_anim or !is_playing():
			play(target_anim)
	else:
		stop()
		animation = target_anim
