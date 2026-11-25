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
func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	super(delta)
	if !playing and play_cooldown > 0.0: play_cooldown -= delta
	
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity = Vector3(direction.x * SPEED_WALK, velocity.y, direction.z * SPEED_WALK)
	walking = direction != Vector3.ZERO
	move_and_slide()

var interactions: Array[StringName] = [&"door", &"item"]
func _process(delta: float) -> void:
	if multiplayer.get_unique_id() != id: return
	$UI/Stamina.value = play_cooldown
	$Music.stop()
	$UI.show()
	super(delta)

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

var play_cooldown: float = 0.0
func _on_area_body_entered(body: Node3D) -> void:
	if !is_multiplayer_authority(): return
	if body == self: return
	if play_cooldown > 0.0: return
	if body.jumping_rope: return
	play_cooldown = 15.0
	body.start_jumping_rope(self)
	play_sound.rpc("ready")
	playing = true

var playing: bool = false
func finished():
	playing = false
	await $"Sounds/5".finished
	play_sound.rpc("congrats")
