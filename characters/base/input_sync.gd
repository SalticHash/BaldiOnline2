extends MultiplayerSynchronizer
class_name BaseInputSync

@onready var player: BaseController = get_parent()
const DPI: float = 0.01

func _ready() -> void:
	if !is_multiplayer_authority():
		process_mode = Node.PROCESS_MODE_DISABLED
		return
	await player.ready
	player.camera.make_current()


func _input(event: InputEvent) -> void:
	
	# TESTING code
	if event is InputEventMouseButton and event.double_click:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED \
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE\
		 else Input.MOUSE_MODE_VISIBLE
	if event is not InputEventMouseMotion: return
			
	var motion: InputEventMouseMotion = event
	
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED: return
	player.rotate_y(-motion.relative.x * DPI)
