extends BaseController

@export var skin: int = 0
enum ITEM {
	NONE,
	BSODA,
	ZESTY
}

const SPEED_WALK: float = 1.67
var walking: bool = false
var item: int = -1

func _enter_tree() -> void:
	super()
	$OwnerSync.set_visibility_for(id, true)
	$Sprite.skin = skin

func _ready() -> void:
	if !is_multiplayer_authority(): return
	set_item()

func set_item() -> void:
	var last_item = item
	var lost = randi_range(1, 10)
	item = Server.MAX_ITEM + lost
	if item == last_item:
		item = wrapi(item - lost, 0, 9) + Server.MAX_ITEM + 1

var input_dir: Vector2 = Vector2.ZERO
func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	var d2 = Server.get_closest(Server.TYPE.PLAYER, global_position)[1]
	if d2 < 1.0 and !$Sounds/yay.playing:
		if !$Cloud.visible: play_sound.rpc("ask")
		$Cloud.show()
	else:
		$Cloud.hide()
	
	super(delta)
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity = Vector3(direction.x * SPEED_WALK, velocity.y, direction.z * SPEED_WALK)
	if jumping_rope:
		velocity.x = 0
		velocity.z = 0
	walking = direction != Vector3.ZERO
	move_and_slide()
	global_position.y = max(global_position.y, 0.0)


var interactions: Array[StringName] = [&"door", &"item"]
func _process(delta: float) -> void:
	$Sprite.yay = $Sounds/yay.playing
	if !$Sounds/yay.playing: $AnimationPlayer.play("RESET")
	$Sprite.walking = walking
	var anim = "l" + str(item - (Server.MAX_ITEM + 1))
	$Cloud/Item.animation = anim
	if multiplayer.get_unique_id() != id: return
	super(delta)
	$UI.show()
	$UI/Slot/Item.animation = anim
	
	var obj = $Camera/InteractRay.get_collider()
	if obj and obj.is_in_group("interact"):
		var interact_id = obj.get_meta(&"interact_id")
		if interact_id in interactions: $UI/Hand.show()
		else: $UI/Hand.hide()

		if Input.is_action_just_pressed("click"):
			match interact_id:
				&"door": obj.open_door.rpc_id(1)
				&"item":
					if obj.item_id == item:
						$PickupSound.play()
						obj.pickup.rpc_id(1)
					else:
						$ErrorSound.play()
	else: $UI/Hand.hide()


@rpc("authority", "call_local", "reliable")
func play_sound(sound):
	if sound == "yay":
		$Sounds/ask.stop()
		$AnimationPlayer.play("yay")
	$Sounds.get_node(sound).play()

func got_item():
	if !is_multiplayer_authority(): return
	play_sound.rpc("yay")
	set_item()
