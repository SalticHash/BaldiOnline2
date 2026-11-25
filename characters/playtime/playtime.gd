extends BaseController

@export var skin: int = 0
enum ITEM {
	NONE,
	BSODA,
	ZESTY
}

const SPEED_WALK: float = 1.3
const SPEED_RUN: float = 2.6

func _ready() -> void:
	if !is_multiplayer_authority(): return

var input_dir: Vector2 = Vector2.ZERO
func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	super(delta)
	if !playing and play_cooldown > 0.0: play_cooldown -= delta
	
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var speed = SPEED_WALK if play_cooldown > 0.0 else SPEED_RUN
	if playing: speed = 0.0
	velocity = Vector3(direction.x * speed, velocity.y, direction.z * speed)
	move_and_slide()
	global_position.y = max(global_position.y, 0.0)


var interactions: Array[StringName] = [&"door", &"item"]
func _process(delta: float) -> void:
	if multiplayer.get_unique_id() != id: return
	$UI/Stamina.value = play_cooldown
	$Music.stop()
	$UI.show()
	super(delta)

@rpc("authority", "call_local", "reliable")
func play_sound(sound):
	$Sounds.get_node(sound).play()
	if sound == "sad":
		$Sprite.play("sad")
		for s in $Sounds.get_children():
			if s.name == "sad": continue
			s.stop()
		

var play_cooldown: float = 0.0
var victim: Node3D = null
func _on_area_body_entered(body: Node3D) -> void:
	if !is_multiplayer_authority(): return
	if body == self: return
	if play_cooldown > 0.0: return
	if body.jumping_rope: return
	play_cooldown = 15.0
	body.start_jumping_rope(self)
	play_sound.rpc("ready")
	playing = true
	victim = body

var playing: bool = false
func finished():
	playing = false
	victim = null
	await $"Sounds/5".finished
	play_sound.rpc("congrats")

func cut_rope():
	if !is_multiplayer_authority(): return
	play_cooldown = 15.0
	play_sound.rpc("sad")
	if victim: victim.finish_jumping_rope()
	victim = null
