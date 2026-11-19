extends Area3D

@export var color: int = 0 :
	set(value):
		color = value
		$Sprite.animation = str(color)

func _ready() -> void:
	$AnimationPlayer.play("hover")

func _process(_delta: float) -> void:
	$Collision.disabled = !visible

@rpc("any_peer", "call_local", "reliable")
func pickup() -> void:
	if !visible: return
	
	if !is_multiplayer_authority():
		push_error("Not received by authority")
		return
	var sender_id = multiplayer.get_remote_sender_id()
	var is_player = Server.get_id_type(sender_id) == Server.TYPE.PLAYER
	var sender_inst = Server.get_id_instance(sender_id)
	var item_dist = sender_inst.global_position.distance_squared_to(global_position)
	if item_dist > sender_inst.reach_squared():
		push_error("Unreachable notebook picked up")
		return
	if !is_player:
		push_error("Non player picked up notebook")
		return
	sender_inst.notebooks += 1
	if sender_inst.notebooks == 7:
		get_node("/root/Game/World/EscapeMusic").play()

	sender_inst.stamina = 1.0
	var baldi = Server.get_type_instance(Server.TYPE.BALDI)
	if baldi: baldi.got_notebook.emit(sender_inst.notebooks)
	hide()
