extends BaseController

enum ITEM {
	NONE,
	QUARTER,
	BSODA,
	DIET,
	ZESTY,
	LOCK,
	GLOVE,
	ANTI_HEARING_TAPE,
}

var lost: bool = false
var cursor_pos: int = 0
const SPEED_RUN: float = 180.0
const SPEED_WALK: float = 80.0
const STAM_LOSS_SPEED: float = 0.25
const STAM_GAIN_SPEED: float = 0.5
var running: bool = false
var inventory: Array[int] = [0, 0, 0, 0, 0]
var locker: NodePath = NodePath("")
var glove_time: float = 0.0
var stamina: float = 1.0 :
	set(value):
		stamina = clampf(value, 0.0, 1.5)

func _enter_tree() -> void:
	super()
	$OwnerSync.set_visibility_for(id, true)

var input_dir: Vector2 = Vector2.ZERO
func _physics_process(delta: float) -> void:
	if is_multiplayer_authority() or multiplayer.get_unique_id() == id:
		$Camera/InteractRay.target_position.z = -100.0 if glove_time > 0.0 else -1.0
	
	if !is_multiplayer_authority(): return
	if lost: return
	if glove_time > 0.0: glove_time -= delta
	if (!input_dir or has_node(locker)) and stamina < 1.0:
		stamina += delta * STAM_GAIN_SPEED
	elif running:
		stamina -= delta * STAM_LOSS_SPEED
	
	if has_node(locker): return
	var speed = SPEED_RUN if running and stamina > 0.0 else SPEED_WALK
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity = direction * speed * delta

	move_and_slide()

@rpc("any_peer","call_local","reliable")
func enter_locker(path):
	if !is_multiplayer_authority(): return
	if !has_node(path): return
	
	var locker_inst = get_node(path)
	var locker_pos = locker_inst.global_position
	if locker_pos.distance_squared_to(global_position) > reach_squared():
		return
	locker_inst.enter_locker.rpc()
	locker = path

@rpc("any_peer","call_local","reliable")
func exit_locker():
	if !is_multiplayer_authority(): return
	var locker_inst = get_node(locker)
	locker_inst.enter_locker.rpc()
	locker = NodePath("")
	
func _process(_delta: float) -> void:
	if has_node(locker):
		$VoiceChat/Voice.bus = &"Muffled"
		$Mesh.hide()
		$Collision.disabled = true
	else:
		$VoiceChat/Voice.bus = &"Master"
		$Mesh.show()
		$Collision.disabled = false
		
	if multiplayer.get_unique_id() != id: return
	$UI.show()
	
	$UI/NotebookAmount.text = str(Server.notebooks) + "/7"
	$UI/Stamina/Needle.position.x = \
	remap(stamina, 0.0, 1.0, $UI/Stamina/Start.position.x, $UI/Stamina/End.position.x)
	
	if glove_time > 0.0:
		$UI/Effects/Glove.show()
		$UI/Effects/Glove/Time.value = glove_time
	else:
		$UI/Effects/Glove.hide()
	
	if has_node(locker):
		get_node(locker).get_node("Camera").make_current()
		$UI/Hand.hide()
		$UI/Cursor.hide()
		$UI/LockerOverlay.show()
		if Input.is_action_just_pressed("click"):
			exit_locker.rpc_id(1)
		return
	else:
		$UI/Cursor.show()
		$UI/LockerOverlay.hide()
		$Camera.make_current()
	
	$Camera.rotation.y = PI if Input.is_action_pressed("flip") else 0.0

	if Input.is_action_just_pressed("scroll_up"):
		cursor_pos -= 1
	if Input.is_action_just_pressed("scroll_down"):
		cursor_pos += 1
	cursor_pos = wrapi(cursor_pos, 0, inventory.size())
	
	# Update inventory
	for i in range(inventory.size()):
		var slot = $UI/Inventory.get_child(i)
		var bg: ColorRect = slot.get_node("BG")
		var anim: AnimatedSprite2D = slot.get_node("Item")
		bg.color = Color.RED if cursor_pos == i else Color.WHITE
		anim.animation = str(inventory[i])
	
	if Input.is_action_just_pressed("use"):
		use_item.rpc_id(1, cursor_pos)
	
	var obj = $Camera/InteractRay.get_collider()
	if obj and obj.is_in_group("interact"):
		$UI/Hand.show()
		if Input.is_action_just_pressed("click"):
			if obj.is_in_group("door"): obj.open_door.rpc_id(1)
			if obj.is_in_group("storage_locker"):
				obj.get_parent().toggle_locker.rpc_id(1)
			if obj.is_in_group("blue_locker"):
				enter_locker.rpc_id(1, obj.get_path())
				
			if obj.is_in_group("item"):
				if !obj.storage_slot or (obj.item_id != 0 or inventory[cursor_pos] != 0):
					$PickupSound.play()
				obj.pickup.rpc_id(1, cursor_pos)
			if obj.is_in_group("notebook"):
				$NotebookPickupSound.play()
				$UI/Notebook.stop()
				$UI/Notebook.play("turn")
				obj.pickup.rpc_id(1)
	else: $UI/Hand.hide()

@onready var bsoda = preload("res://bsoda/bsoda.tscn")
@onready var diet = preload("res://bsoda/diet.tscn")
@rpc("any_peer", "call_local", "reliable")
func use_item(cursor):
	if !is_multiplayer_authority(): return
	var item = inventory[cursor]
	match item:
		ITEM.NONE: return
		ITEM.BSODA, ITEM.DIET:
			var b = (bsoda if item == ITEM.BSODA else diet).instantiate()
			get_parent().get_parent().get_node("Instances").add_child(b, true)
			b.global_position = global_position
			b.global_rotation = $Camera.global_rotation
			play_sound.rpc("bsoda")
			inventory[cursor] = ITEM.NONE
			return
		ITEM.ZESTY:
			play_sound.rpc("zesty")
			stamina = 1.5
			inventory[cursor] = ITEM.NONE
			return
		ITEM.LOCK:
			var c = $Camera/InteractRay.get_collider()
			if !c or !c.is_in_group("swinging_door") or c.locked:
				$InvalidUse.play()
				return
			inventory[cursor] = ITEM.NONE
			c.lock.rpc()
			return
		ITEM.GLOVE:
			inventory[cursor] = ITEM.NONE
			play_sound.rpc("glove")
			glove_time = 60.0
			return
		ITEM.ANTI_HEARING_TAPE:
			var c = $Camera/InteractRay.get_collider()
			if !c or !c.is_in_group("tape_player") or c.phone or !c.open:
				$InvalidUse.play()
				return
			inventory[cursor] = ITEM.NONE
			c.anti_hearing()
		ITEM.QUARTER:
			var c = $Camera/InteractRay.get_collider()
			if !c:
				$InvalidUse.play()
				return
			if c.is_in_group("tape_player") and c.phone:
				inventory[cursor] = ITEM.NONE
				c.anti_hearing()
				return
			if c.is_in_group("vending_machine") and c.uses > 0:
				inventory[cursor] = c.get_item_id()
				c.use()
				return
			

func reach_squared() -> float:
	var v = (-$Camera/InteractRay.target_position.z + 1.0)
	return v * v

@rpc("authority", "call_local", "reliable")
func play_sound(sound):
	$Sounds.get_node(sound).play()

func lose():
	if !is_multiplayer_authority(): return
	lost = true
