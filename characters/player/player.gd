extends BaseController

enum ITEM {
	NONE,
	BSODA,
	ZESTY
}

var cursor_pos: int = 0
const SPEED_RUN: float = 180.0
const SPEED_WALK: float = 80.0
const STAM_LOSS_SPEED: float = 0.25
const STAM_GAIN_SPEED: float = 0.5
var running: bool = false
var inventory: Array[int] = [0, 0, 0, 0, 0]

var stamina: float = 1.0 :
	set(value):
		stamina = clampf(value, 0.0, 1.0)

func _enter_tree() -> void:
	super()
	$OwnerSync.set_visibility_for(id, true)

var notebooks: int = 0 :
	set(value):
		notebooks = value
		$UI/NotebookAmount.text = str(notebooks) + "/7"
var input_dir: Vector2 = Vector2.ZERO
func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	
	if !input_dir: stamina += delta * STAM_GAIN_SPEED
	elif running: stamina -= delta * STAM_LOSS_SPEED
	
	var speed = SPEED_RUN if running and stamina > 0.0 else SPEED_WALK
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity = direction * speed * delta

	move_and_slide()

func _process(_delta: float) -> void:
	if multiplayer.get_unique_id() != id: return
	$Camera.rotation.y = PI if Input.is_action_pressed("flip") else 0.0
	$UI/Stamina/Needle.position.x = \
		remap(stamina, 0.0, 1.0, $UI/Stamina/Start.position.x, $UI/Stamina/End.position.x)
	$UI.show()
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
	
	var obj = $Camera/InteractRay.get_collider()
	if obj and obj.is_in_group("interact"):
		$UI/Hand.show()
		if Input.is_action_just_pressed("click"):
			if obj.is_in_group("door"): obj.open_door.rpc_id(1)
			if obj.is_in_group("item"):
				$PickupSound.play()
				obj.pickup.rpc_id(1, cursor_pos)
			if obj.is_in_group("notebook"):
				$NotebookPickupSound.play()
				$UI/Notebook.play("turn")
				obj.pickup.rpc_id(1)
	else: $UI/Hand.hide()
