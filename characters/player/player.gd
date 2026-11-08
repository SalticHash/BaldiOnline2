extends BaseController

const SPEED_RUN: float = 180.0
const SPEED_WALK: float = 80.0
const STAM_LOSS_SPEED: float = 0.25
const STAM_GAIN_SPEED: float = 0.5
var running: bool = false
var stamina: float = 1.0 :
	set(value):
		stamina = clampf(value, 0.0, 1.0)

func _enter_tree() -> void:
	super()
	$OwnerSync.set_visibility_for(id, true)
	
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
	$UI/Stamina.value = stamina
	$UI.show()
	if Input.is_action_just_pressed("click"):
		var obj = $Camera/InteractRay.get_collider()
		if obj and obj.is_in_group("door"):
			obj.open_door.rpc_id(1)
