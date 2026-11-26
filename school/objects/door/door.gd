extends Area3D

var open: bool = false
@export_enum("normal", "faculty", "suplies", "wooden", "men", "women", "principal", "mystery", "office", "lab", "safe", "doctor") var door_front: String = "normal"
@export_enum("normal", "faculty", "suplies", "wooden", "men", "women", "principal", "mystery", "office", "lab", "safe", "doctor") var door_back: String = "normal"
@export var front_material: Material
@export var back_material: Material
# Request current door state and connects timer if on authority
func _ready() -> void:
	$Collisions/Front/Mesh.material_override = front_material
	$Collisions/Back/Mesh.material_override = back_material
	request_state.rpc_id(1)
	if is_multiplayer_authority():
		$Timer.timeout.connect(close_door)

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
	$Collisions/Solid/Collision.set_deferred("disabled", open)
	$DoorFrame.set_deferred("disabled", open)
	
	if state == false:
		if !request: $Sounds/Close.play()
		$Sprites/DoorSpriteFront.play(door_front + "_close")
		$Sprites/DoorSpriteBack.play(door_back + "_close")
	if state == true && old_state == false:
		if !request: $Sounds/Open.play()
		$Sprites/DoorSpriteFront.play(door_front + "_open")
		$Sprites/DoorSpriteBack.play(door_front + "_open")

# Anyone can try and open the door
@rpc("any_peer", "call_local", "reliable")
func open_door(id: int = -1):
	if !is_multiplayer_authority():
		push_error("OPEN DOOR REQUEST should be to AUTHORITY ONLY")
		return
	var sender_id = multiplayer.get_remote_sender_id() if id == -1 else id
	var is_player = Server.get_id_type(sender_id) == Server.TYPE.PLAYER
	var sender_inst = Server.get_id_instance(sender_id)
	var door_dist = sender_inst.global_position.distance_squared_to(global_position)
	if door_dist > sender_inst.reach_squared():
		push_error("Unreachable door opened")
		return
	if is_player and !open:
		Server.alert_baldi(10, $SP.global_position)
	change_state.rpc(true)
	$Timer.start()

# Called when door timer closes (ON SERVER)
func close_door():
	change_state.rpc(false)


func _on_body_entered(body: Node3D) -> void:
	if !is_multiplayer_authority(): return
	if body.is_in_group(&"baldi") or body.is_in_group(&"sweep"):
		open_door(body.id)
