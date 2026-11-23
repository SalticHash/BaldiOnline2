extends MultiplayerSynchronizer
class_name BaseInputSync

@onready var player: BaseController = get_parent()
var DPI: float = 0.01

func _ready() -> void:
	if !is_multiplayer_authority():
		process_mode = Node.PROCESS_MODE_DISABLED
		return
	await player.ready
	player.camera.make_current()


func _input(event: InputEvent) -> void:
	if OS.has_feature("mobile"):
		get_window().mode = Window.MODE_FULLSCREEN
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if event is InputEventKey and event.is_pressed() and !event.is_echo():
		match event.keycode:
			KEY_F11:
				get_window().mode = Window.MODE_FULLSCREEN
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

			KEY_F10:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED \
				if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE\
				else Input.MOUSE_MODE_VISIBLE
			KEY_UP: DPI += 0.0005
			KEY_DOWN: DPI -= 0.0005
		DPI = clampf(DPI, 0.0, 1.0)
	
	if event is not InputEventMouseMotion: return
	var motion: InputEventMouseMotion = event
	if OS.has_feature("mobile"):
		var inside_joystick_area: bool = %VirtualJoystick.get_global_rect().has_point(motion.global_position)
		if inside_joystick_area: return
	player.rotate_y(-motion.relative.x * DPI)
