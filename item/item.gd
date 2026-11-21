extends Area3D

@export var present: bool = false
@export var storage_slot: bool = false
@export var item_id: int = 1 :
	set(value):
		item_id = value
		var lost_i = item_id > 9
		var rid = item_id - 10 if lost_i else item_id
		$Sprite.animation = ("l" if lost_i else "") + str(rid)

func _ready() -> void:
	if storage_slot: return
	$AnimationPlayer.play("hover")
	if present:
		item_id = randi_range(1, 8) #TODO DFIX WITH MISSING IDS
		$Sprite.animation = "present"
		

func _process(_delta: float) -> void:
	$Collision.disabled = !visible

@rpc("any_peer", "call_local", "reliable")
func pickup(cursor_pos) -> void:
	if !visible: return
	
	if !is_multiplayer_authority():
		push_error("Not received by authority")
		return
	var sender_id = multiplayer.get_remote_sender_id()
	var is_player = Server.get_id_type(sender_id) == Server.TYPE.PLAYER
	var sender_inst = Server.get_id_instance(sender_id)
	var item_dist = sender_inst.global_position.distance_squared_to(global_position)
	if item_dist > sender_inst.reach_squared():
		push_error("Unreachable item picked up")
		return
	if !is_player:
		push_error("Non player picked up")
		return
	var inv = sender_inst.inventory
	if storage_slot:
		var held_item = inv[cursor_pos]
		inv[cursor_pos] = item_id
		item_id = held_item
		return
	
	if inv[cursor_pos] != 0:
		for i in range(inv.size()):
			if inv[i] != 0: continue
			cursor_pos = i
			break
	if inv[cursor_pos] == 0:
		inv[cursor_pos] = item_id
		hide()
	else:
		var held_item = inv[cursor_pos]
		inv[cursor_pos] = item_id
		item_id = held_item
		
