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
	APPLE,
	ALARM_CLOCK,
	SCISSORS, #10
	
	LOST_BOOK,
	LOST_CARDS,
	LOST_CONTROLLER,
	LOST_FIGURE,
	LOST_FLOPPY,
	LOST_MARKER,
	LOST_PLUSH,
	LOST_PUPPET,
	LOST_TAPE,
	LOST_TRAIN,
}

var lost: bool = false
var cursor_pos: int = 0
const SPEED_RUN: float = 2.5
const SPEED_WALK: float = 1.67
const STAM_LOSS_SPEED: float = 0.1
const STAM_GAIN_SPEED: float = 0.2
var running: bool = false
var inventory: Array[int] = [10, 10, 0, 0, 0]
var locker: NodePath = NodePath("")
var glove_time: float = 0.0
var stamina: float = 1.0 :
	set(value):
		stamina = clampf(value, 0.0, 2.0)

func can_interact() -> bool:
	return !lost and !has_node(locker)

# Pasto
# Duracion regenerar (descansando): 3.3s
# Duracion regenerar (caminando): 10s
# Uso al correr: 0

# El resto
#Duracion regenerar (descansando): 5s
#Duracion usar (corriendo): 10s
# Uso al caminar: 0

func _enter_tree() -> void:
	super()
	$OwnerSync.set_visibility_for(id, true)

var input_dir: Vector2 = Vector2.ZERO
func _physics_process(delta: float) -> void:
	if is_multiplayer_authority() or multiplayer.get_unique_id() == id:
		$Camera/InteractRay.target_position.z = -100.0 if glove_time > 0.0 else -1.0
	
	if !is_multiplayer_authority(): return
	super(delta)
	if lost: return
	if glove_time > 0.0: glove_time -= delta
	if (!input_dir or has_node(locker)) and stamina < 1.0:
		stamina += delta * STAM_GAIN_SPEED
	elif running and input_dir:
		stamina -= delta * STAM_LOSS_SPEED
	
	if has_node(locker) or (jumping_rope and !jumping): return
	var speed = SPEED_RUN if running and stamina > 0.0 else SPEED_WALK
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	move_and_slide()
	global_position.y = max(global_position.y, 0.0)

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
	entered_locker.rpc()

@rpc("authority","call_local","reliable")
func entered_locker():
	$VoiceChat/Voice.bus = &"Muffled"
	hide()
	$Collision.disabled = true

@rpc("any_peer","call_local","reliable")
func exit_locker():
	if !is_multiplayer_authority(): return
	var locker_inst = get_node(locker)
	locker_inst.enter_locker.rpc()
	locker = NodePath("")
	exited_locker.rpc()

@rpc("authority","call_local","reliable")
func exited_locker():
	$VoiceChat/Voice.bus = &"Master"
	show()
	$Collision.disabled = false

func _process(delta: float) -> void:
	if multiplayer.get_unique_id() != id: return
	super(delta)
	if lost:
		get_node("/root/Game/World/Skybox").hide()
		var s = $Camera/Darkness.mesh.size.x
		var l = 0.5
		if s <= l:
			$UI/Darkness.show()
			$Lose.stop()
			return
		s = clampf(s - (delta * 80 / 1.2), l, 80.5)
		$Camera/Darkness.mesh.size = Vector3(s, 80.5, s)
	
	$UI.show()
	$Camera/Darkness.show()
	$Camera/Hand3D.hide()
	$Camera/Darkness.global_position = $Camera.global_position
	$UI/NotebookAmount.text = str(Server.notebooks) + "/7"
	
	$UI/Stamina.value = stamina
	
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


	
	# Update inventory
	update_inventory()
	
	interact()
	if Input.is_action_just_pressed("use"):
		use_item.rpc_id(1, cursor_pos)

func update_inventory():
	for i in range(inventory.size()):
		var slot = $UI/Inventory.get_child(i)
		
		var bg: ColorRect = slot.get_node("BG")
		bg.color = Color.RED if cursor_pos == i else Color.WHITE
		
		var anim: AnimatedSprite2D = slot.get_node("Item")
		var it = inventory[i]
		var lost_i = it > Server.MAX_ITEM
		var rid = it - (Server.MAX_ITEM + 1) if lost_i else it
		anim.animation = ("l" if lost_i else "") + str(rid)
	
	if !can_interact(): return
	if Input.is_action_just_pressed("scroll_up"): cursor_pos -= 1
	if Input.is_action_just_pressed("scroll_down"): cursor_pos += 1
	if Input.is_action_just_pressed("slot_1"): cursor_pos = 0
	if Input.is_action_just_pressed("slot_2"): cursor_pos = 1
	if Input.is_action_just_pressed("slot_3"): cursor_pos = 2
	if Input.is_action_just_pressed("slot_4"): cursor_pos = 3
	if Input.is_action_just_pressed("slot_5"): cursor_pos = 4
	cursor_pos = wrapi(cursor_pos, 0, inventory.size())

var interactions = [&"door", &"storage_locker", &"blue_locker", &"alarm_clock", &"item", &"notebook"]
func interact() -> void:
	var obj: Node3D = $Camera/InteractRay.get_collider()
	var interact_id = obj.get_meta(&"interact_id", null) if obj and obj.is_in_group("interact") else null
	if !interact_id \
		or interact_id not in interactions \
		or !can_interact():
		$UI/Hand.hide()
		return
	$UI/Hand.show()

	if !Input.is_action_just_pressed("click"): return
	match interact_id:
		&"door": obj.open_door.rpc_id(1)
		&"storage_locker": obj.get_parent().toggle_locker.rpc_id(1)
		&"blue_locker": enter_locker.rpc_id(1, obj.get_path())
		&"alarm_clock": obj.wind.rpc_id(1)
		&"item":
			var empty = obj.item_id == 0 and inventory[cursor_pos] == 0
			if !obj.storage_slot or !empty: $PickupSound.play()
			obj.pickup.rpc_id(1, cursor_pos)
		&"notebook":
			$NotebookPickupSound.play()
			$UI/Notebook.stop()
			$UI/Notebook.play("turn")
			obj.pickup.rpc_id(1)
	
@onready var bsoda = preload("res://bsoda/bsoda.tscn")
@onready var diet = preload("res://bsoda/diet.tscn")
@onready var alarm_clock = preload("res://alarm_clock/alarm_clock.tscn")
@rpc("any_peer", "call_local", "reliable")
func use_item(cursor):
	if !is_multiplayer_authority(): return
	var item = inventory[cursor]
	var c = $Camera/InteractRay.get_collider()
	var interact_id = c.get_meta(&"interact_id") if c and c.is_in_group("interact") else null
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
		ITEM.ALARM_CLOCK:
			var cl = alarm_clock.instantiate()
			get_parent().get_parent().get_node("Instances").add_child(cl, true)
			cl.global_position = global_position
			inventory[cursor] = ITEM.NONE
			return
		ITEM.ZESTY:
			play_sound.rpc("zesty")
			stamina = 2.0
			inventory[cursor] = ITEM.NONE
			return
		ITEM.LOCK:
			if interact_id != &"swingdoor" or c.locked:
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
			if interact_id != &"tape_player" or !c.open:
				$InvalidUse.play()
				return
			inventory[cursor] = ITEM.NONE
			c.anti_hearing()
		ITEM.QUARTER:
			if !interact_id:
				$InvalidUse.play()
				return
			if interact_id == &"payphone":
				inventory[cursor] = ITEM.NONE
				c.anti_hearing()
				return
			if interact_id == &"vending_machine" and c.uses > 0:
				inventory[cursor] = c.get_item_id()
				c.use()
				return
		ITEM.SCISSORS:
			if interact_id != &"playtime" or (c.play_cooldown > 0.0 and !c.playing):
				$InvalidUse.play()
				return
			play_sound.rpc("scissors")
			c.cut_rope()
			inventory[cursor] = ITEM.NONE
		_:
			if item <= Server.MAX_ITEM: return
			if interact_id == &"student" and c.item == item:
				play_sound.rpc("quarter")
				c.got_item()
				inventory[cursor] = ITEM.NONE
			elif interact_id == &"tape_player" and c.open and item == ITEM.LOST_TAPE:
				c.funtime()
				inventory[cursor] = ITEM.NONE
				return
			else:
				$InvalidUse.play()
				
			

@rpc("authority", "call_local", "reliable")
func play_sound(sound):
	$Sounds.get_node(sound).play()

func lose(b):
	if !is_multiplayer_authority(): return
	if lost: return
	lost = true
	got_by_baldi.rpc(b.get_path())

@rpc("authority", "call_local", "reliable")
func got_by_baldi(path):
	if multiplayer.get_unique_id() != id:
		hide()
		return
	$VoiceChat.stop()
	$UI/Baldi.show()
	$Lose.play()
	get_node(path).hide()

func has_item(item: ITEM) -> int:
	if !is_multiplayer_authority():
		push_error("Cant check as is not authority")
		return false
	return inventory.find(item)

func set_item(slot: int, item: ITEM) -> void:
	if !is_multiplayer_authority():
		push_error("Cant set as is not authority")
		return
	inventory[slot] = item
