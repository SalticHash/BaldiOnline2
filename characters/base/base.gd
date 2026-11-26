extends CharacterBody3D
class_name BaseController

#region HELPERS
func is_server() -> bool:
	return is_multiplayer_authority()

func is_owner() -> bool:
	return id == multiplayer.get_unique_id()
#endregion

var id: int = 1 #TODO FIX
var username: String = ""
@onready var camera: Camera3D = $Camera
func _enter_tree() -> void:
	$InputSync.set_multiplayer_authority(id)
	$PeerSync.set_multiplayer_authority(id)
	$InputSync.set_visibility_for(1, true)
	$OwnerSync.set_visibility_for(id, true)
	$Jumprope/RopeSync.set_visibility_for(id, true)
	if OS.has_feature("mobile") and multiplayer.get_unique_id() == id:
		%VirtualJoystick.show()
	$NameLabel.text = username
	
	if !is_multiplayer_authority(): return
	$Jumprope/Rope.frame_changed.connect(count_jump)

func _physics_process(delta: float) -> void:
	if !is_server(): return
	jump_physics(delta)

func _process(_delta: float) -> void:
	if !is_owner(): return
	update_rope()

#region JUMP_LOGIC
var jumping_rope: bool = false # Synced with owner
var jump_count = 0 # Synced with owner
var playtime_inst = null
var jumping = false

func jump_physics(delta): # Auth
	if jumping:
		velocity.y -= 2.0 * delta
		if global_position.y <= 0.0 and velocity.y < 0:
			jumping = false
	else:
		velocity.y = 0.0
		global_position.y = 0.0

func update_rope(): # Owner
	$Jumprope/Label.text = str(jump_count)
	$Jumprope.visible = jumping_rope

@rpc("any_peer", "call_local", "reliable")
func jump(): # Invoked by owner, run in auth
	if !is_multiplayer_authority(): return
	if !jumping_rope: return
	jumping = true
	velocity.y = 1.0

func count_jump(): # Connected to frame_changed in auth
	if $Jumprope/Rope.frame != 12: return
	if jumping:
		jump_count += 1
		playtime_inst.play_sound.rpc(str(jump_count))
		if jump_count == 5: finish_jumping_rope()
	else:
		jump_count = 0
		playtime_inst.play_sound.rpc("oops")

@rpc("authority", "call_local", "reliable")
func jump_rope(): # Invoked by auth, run in owner
	$Jumprope/Rope.play()

func start_jumping_rope(inst): # Called by auth
	playtime_inst = inst
	jumping_rope = true
	$Jumprope/Rope.play()
	jump_rope.rpc_id(id)
	jump_count = 0

func finish_jumping_rope(): # Called by auth
	playtime_inst.finished()
	jumping_rope = false
	jump_count = 0
	$Jumprope/Rope.stop()
	playtime_inst = null

#endregion

func reach_squared() -> float:
	var v = (-$Camera/InteractRay.target_position.z + 1.0)
	return v * v
