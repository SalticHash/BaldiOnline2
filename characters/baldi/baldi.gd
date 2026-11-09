extends BaseController

const SPEED: float = 450.0

var slapping: bool = false
var slap_buffer: float = 0.0
var slap_interval: float = 0.0
const SLAP_BUFFER: float = 0.167 #10 frames in a 60fps game
const SLAP_INTERVAL: float = 1.2
func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return

	slap_buffer -= delta
	slap_interval -= delta
	if slapping and slap_interval <= 0.0:
		slap_buffer = SLAP_BUFFER
		slap_interval = SLAP_INTERVAL
		slap_effect.rpc()
	if slap_buffer > 0.0:
		var direction := (transform.basis * Vector3.FORWARD).normalized()
		velocity = direction * SPEED * delta
	else:
		velocity = Vector3.ZERO

	move_and_slide()


@rpc("authority", "call_local", "reliable")
func slap_effect():
	$Sprite.play("slap")
	$SlapSound.play()

func _process(_delta: float) -> void:
	if multiplayer.get_unique_id() != id: return
	$UI/Stamina.value = slap_interval
	$UI.show()
