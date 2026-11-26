extends MultiplayerSynchronizer
class_name BaseInputSync

@onready var player: BaseController = get_parent()
var DPI: float = 0.01

func _ready() -> void:
	if OS.has_feature("pc"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if !is_multiplayer_authority():
		process_mode = Node.PROCESS_MODE_DISABLED
		return
	await player.ready
	player.camera.make_current()
	if OS.has_feature("mobile"):
		%VirtualJoystick.show()
		%TouchArea.gui_input.connect(_touch_input)


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("click"):
		player.jump.rpc_id(1)
	
	if event is InputEventKey and event.is_pressed() and !event.is_echo():
		match event.keycode:
			KEY_F11:
				get_window().mode = Window.MODE_FULLSCREEN
			KEY_F10:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED \
				if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE\
				else Input.MOUSE_MODE_VISIBLE
			KEY_UP: DPI += 0.0005
			KEY_DOWN: DPI -= 0.0005
		DPI = clampf(DPI, 0.0, 1.0)
	
	if event is InputEventMouseMotion and !OS.has_feature("mobile"):
		player.rotate_y(-event.relative.x * DPI)
	if event is InputEventScreenDrag:
		var inside_touch_area: bool = %TouchArea.get_global_rect().has_point(event.position)
		if !inside_touch_area: return
		player.rotate_y(-event.relative.x * DPI)


var last_touch_idx: int = -1
var last_touch_epoch: int = 0 
func _touch_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.is_pressed():
			last_touch_idx = event.index
			last_touch_epoch = Time.get_ticks_msec()
			
		elif event.index == last_touch_idx:
			var delta = Time.get_ticks_msec() - last_touch_epoch
			if delta > 350:
				last_touch_idx = -1
				return
			Input.action_press("click")
			Input.action_release("click")
		
