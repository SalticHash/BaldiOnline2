extends BaseController

const SPEED: float = 450.0

var slapping: bool = false
var slap_buffer: float = 0.0
var slap_interval: float = 0.0
const SLAP_BUFFER: float = 0.167 #10 frames in a 60fps game
var SLAP_INTERVAL: float = 1.2

signal got_notebook(total: int)
func _ready() -> void:
	if !is_multiplayer_authority(): return
	got_notebook.connect(speed_up)

func speed_up(_total_notebooks: int):
	SLAP_INTERVAL -= 0.1

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return

	slap_buffer -= delta
	if slap_interval > 0.0: slap_interval -= delta
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
	var v = remap(slap_interval, SLAP_INTERVAL, 0.0, $UI/Stamina/Start.position.x - 96.0, $UI/Stamina/End.position.x)
	var tween = create_tween().set_trans(Tween.TRANS_SINE)
	var y = $UI/Stamina/Needle.position.y
	tween.tween_property($UI/Stamina/Needle, "position", Vector2(v, y), 0.1)
		
	$UI.show()


@onready var player_hightlight = preload("res://characters/baldi/player_highlight.tscn")
@rpc("authority", "call_local", "reliable")
func spawn_highlight(player_position: Vector3, loudness: float):
	# Is not baldi owner
	if multiplayer.get_unique_id() != id:
		push_error("Spawn highlight invoked for non baldi owner")
		return
	
	
	var inst = player_hightlight.instantiate()
	inst.loudness = loudness
	$Highlights.add_child(inst)
	inst.global_position = player_position
