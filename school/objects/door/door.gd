extends Area3D

var open: bool = false
@export_enum("normal", "faculty", "suplies", "wooden") var door_front: String = "normal"
@export_enum("normal", "faculty", "suplies", "wooden") var door_back: String = "normal"
@export var front_material: Material
@export var back_material: Material
# Request current door state and connects timer if on authority
func _ready() -> void:
	$Collisions/Front/Mesh.material_override = front_material
	$Collisions/Back/Mesh.material_override = back_material
	request_state.rpc_id(1)
	if is_multiplayer_authority():
		$Timer.timeout.connect(close_door)

func _process(delta: float) -> void:
	var gb = remap($HighlightTimer.time_left, $HighlightTimer.wait_time, 0.0, 0.0, 1.0)
	$Sprites/DoorSpriteBack.modulate = Color(1.0, gb, gb)
	$Sprites/DoorSpriteFront.modulate = Color(1.0, gb, gb)

# Client requests the current state.
@rpc("any_peer", "call_local", "reliable")
func request_state():
	if !is_multiplayer_authority():
		push_error("REQUEST STATE call should be to AUTHORITY ONLY")
		return
	var sender = multiplayer.get_remote_sender_id()
	change_state.rpc_id(sender, open, true)


# ONLY AUTHORITY can change state
@rpc("authority", "call_local", "reliable")
func change_state(state: bool, request: bool = false):
	var old_state = open
	open = state
	var spr_state = "_open" if state else "_close"
	$Sprites/DoorSpriteBack.play(door_back + spr_state)
	$Sprites/DoorSpriteFront.play(door_front + spr_state)
	$Collisions/Solid/Collision.set_deferred("disabled", open)
	
	if request: return
	if state == false: $Sounds/Close.play()
	if state == true && old_state == false: $Sounds/Open.play()

# Anyone can try and open the door
@rpc("any_peer", "call_local", "reliable")
func open_door(player: bool = false):
	if !is_multiplayer_authority():
		push_error("OPEN DOOR REQUEST should be to AUTHORITY ONLY")
		return
	if player and !open:
		var baldiId = Server.get_type_id(1)
		highlight.rpc_id(baldiId)
	change_state.rpc(true)
	$Timer.start()

# Called when door timer closes (ON SERVER)
func close_door():
	change_state.rpc(false)

@rpc("any_peer", "call_local", "reliable")
func highlight():
	$Sprites/DoorSpriteBack.no_depth_test = true
	$Sprites/DoorSpriteFront.no_depth_test = true
	$HighlightTimer.start()


func _on_body_entered(body: Node3D) -> void:
	if !is_multiplayer_authority(): return
	if body.is_in_group(&"baldi"):
		open_door()
		


func _on_highlight_timer_timeout() -> void:
	$Sprites/DoorSpriteBack.no_depth_test = false
	$Sprites/DoorSpriteFront.no_depth_test = false
