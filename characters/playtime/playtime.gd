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

func _ready() -> void:
	if !is_multiplayer_authority(): return
	item = randi_range(10, 19)

var input_dir: Vector2 = Vector2.ZERO
func _physics_process(_delta: float) -> void:
	if !is_multiplayer_authority(): return

	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity = direction * SPEED_WALK
	walking = direction != Vector3.ZERO
	move_and_slide()

var interactions: Array[StringName] = [&"door", &"item"]
func _process(_delta: float) -> void:
	if multiplayer.get_unique_id() != id: return
	$Music.stop()
	$UI.show()
	$UI/Slot/Item.animation = "l" + str(item - 10)
	
	#var obj = $Camera/InteractRay.get_collider()
	#if obj and obj.is_in_group("interact"):
		#var interact_id = obj.get_meta(&"interact_id")
		#if interact_id in interactions: $UI/Hand.show()
		#else: $UI/Hand.hide()
#
		#if Input.is_action_just_pressed("click"):
			#match interact_id:
				#&"door": obj.open_door.rpc_id(1)
				#&"item":
					#if obj.item_id == item:
						#$PickupSound.play()
						#obj.pickup.rpc_id(1)
					#else:
						#$ErrorSound.play()
	#else: $UI/Hand.hide()

func reach_squared() -> float:
	var v = (-$Camera/InteractRay.target_position.z + 1.0)
	return v * v

@rpc("authority", "call_local", "reliable")
func play_sound(sound):
	$Sounds.get_node(sound).play()

func got_item():
	if !is_multiplayer_authority(): return
	play_sound.rpc("yay")
	var litem = item
	item = randi_range(10, 19)
	if item == litem: item = wrapi(litem - 1, 10, 19)
