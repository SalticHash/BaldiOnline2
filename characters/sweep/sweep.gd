extends BaseController

@export var skin: int = 0

const SPEED_SWEEP: float = 8.35
const SPEED_WALK: float = 1.67
@onready var follower: PathFollow3D = $Follower
@onready var sweep_origin: Path3D = get_node("/root/Game/World/School/Travel/SweepOrigin")
func _ready() -> void:
	if !is_multiplayer_authority(): return
	follower.reparent(sweep_origin)

var input_dir: Vector2 = Vector2.ZERO
var path_dir: float = 1.0
var direction: Vector3 = Vector3.ZERO
var last_direction: Vector3 = Vector3.ZERO
var target_sweep_angle: float = 0.0
var sweeping: bool = true
func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	#if direction:
		#velocity = direction * SPEED_WALK
	super(delta)
	if sweeping: sweep_move(delta)
	else: move()

func move():
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity = Vector3(direction.x * SPEED_WALK, velocity.y, direction.z * SPEED_WALK)
	if jumping_rope:
		velocity.x = 0
		velocity.z = 0
	move_and_slide()
	global_position.y = max(global_position.y, 0.0)

#region SWEEP
func sweep_move(delta):
	follower.progress += delta * SPEED_SWEEP * path_dir
	if follower.progress_ratio == 0.0 or follower.progress_ratio == 1.0:
		global_position.x = snapped(global_position.x, 1.0)
		global_position.z = snapped(global_position.z, 1.0)
		var p = get_directed_path()
		if p:
			follower.reparent(p[0])
			follower.progress_ratio = p[1]
			path_dir = -1.0 if p[1] == 1.0 else 1.0

	var lpos = global_position
	global_position = follower.global_position
	direction = global_position - lpos
	if direction:
		last_direction = direction


func get_all_connected_paths() -> Array[Array]:
	var pos: Vector3 = follower.global_position
	var p1: Node3D = get_node("/root/Game/World/School/Travel")
	var connected: Array[Array] = []
	for travel_path: Path3D in p1.get_children():
		#if travel_path == follower.get_parent(): continue
		var c = travel_path.curve
		var start = c.get_point_position(0)
		var end = c.get_point_position(c.point_count - 1)
		if start == pos:
			connected.append([travel_path, 0.0])
		if end == pos:
			connected.append([travel_path, 1.0])
	return connected

## Returns null or [Path3D, float]
func get_directed_path(ignore_press: bool = false) -> Variant:
	var pressed_direction: Vector3 = Vector3(input_dir.x, 0, input_dir.y)
	if last_direction.x and pressed_direction.z: pressed_direction.x = 0.0
	if last_direction.z and pressed_direction.x: pressed_direction.z = 0.0
	if !input_dir or ignore_press:
		pressed_direction = last_direction
	var pos: Vector3 = follower.global_position + pressed_direction
	var ps = get_all_connected_paths()
	if ps.size() == 0: return null
	if ps.size() == 1: return ps[0]
	for p in ps:
		var path: Path3D = p[0]
		var c = path.curve
		var l = c.get_baked_length()
		var close_point = c.sample_baked(l - 1) if p[1] == 1.0 else c.sample_baked(1)
		var dist = close_point.distance_squared_to(pos)
		if dist <= 1.0:
			return p
	if ignore_press:
		var current_path = follower.get_parent()
		if current_path == sweep_origin: return null
		for p in ps: if p[0] != current_path: return p
	return get_directed_path(true)
#endregion

#var interactions: Array[StringName] = [&"door", &"item"]
func _process(delta: float) -> void:
	if multiplayer.get_unique_id() != id:
		$Sprite.visible = !sweeping
		$Riding.visible = sweeping
		return
	
	if sweeping:
		$TopCamera.global_position = global_position + Vector3(.0, 4.5, .0)
		$TopCamera.make_current()
		$TopCamera/Sprite.show()
		$Sprite.hide()
		target_sweep_angle = atan2(last_direction.x, last_direction.z)
		$TopCamera/Sprite.rotation.z = lerp_angle(
			$TopCamera/Sprite.rotation.z, target_sweep_angle, delta * 20.0
		)
	else:
		$Camera.make_current()
		$Sprite.show()
		$TopCamera/Sprite.hide()
	
	if OS.has_feature("mobile"):
		%VirtualJoystick.visible = !sweeping
		%Arrows.visible = sweeping

	$UI.show()

@rpc("authority", "call_local", "reliable")
func play_sound(sound):
	$Sounds.get_node(sound).play()
