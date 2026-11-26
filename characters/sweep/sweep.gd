extends BaseController

@export var skin: int = 0

const SPEED_WALK: float = 10.67
@onready var follower: PathFollow3D = $Follower
func _ready() -> void:
	if !is_multiplayer_authority(): return
	follower.reparent(get_node("/root/Game/World/School/Travel/SweepOrigin"))

var input_dir: Vector2 = Vector2.ZERO
var dir = 1.0
func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	#if direction:
		#velocity = direction * SPEED_WALK
	
	follower.progress += delta * SPEED_WALK * dir
	if follower.progress_ratio == 0.0 or follower.progress_ratio == 1.0:
		global_position.x = snapped(global_position.x, 1.0)
		global_position.z = snapped(global_position.z, 1.0)
		var p = get_directed_path()
		if !p: return
		follower.reparent(p[0])
		follower.progress_ratio = p[1]
		dir = -1 if p[1] == 1.0 else 1
		
		#follower.reparent(p[0])
		#follower.progress_ratio = p[1]
	global_position = follower.global_position

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
func get_directed_path() -> Variant:
	if !input_dir: return
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var pos: Vector3 = follower.global_position + direction
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
	return null

var interactions: Array[StringName] = [&"door", &"item"]
func _process(_delta: float) -> void:
	if multiplayer.get_unique_id() != id: return
	$Camera3D.make_current()

	$UI.show()

@rpc("authority", "call_local", "reliable")
func play_sound(sound):
	$Sounds.get_node(sound).play()
