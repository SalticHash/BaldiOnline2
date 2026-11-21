extends BaseController

const SPEED: float = 7.5

var slapping: bool = false
var slap_buffer: float = 0.0
var slap_interval: float = 0.0
const SLAP_BUFFER: float = 0.167 #10 frames in a 60fps game
var SLAP_INTERVAL: float = 1.0
var apple: float = 0.0

func _physics_process(delta: float) -> void:

	if !is_multiplayer_authority(): return
	if $Area.has_overlapping_bodies() and !has_node(locker) and apple <= 0.0:
		for b in $Area.get_overlapping_bodies():
			if b.lost: break
			var i = b.has_item(b.ITEM.APPLE)
			if i != -1:
				b.set_item(i, b.ITEM.NONE)
				apple = 15.0
				get_apple.rpc()
				break
			b.lose(self)
	
	SLAP_INTERVAL = 1.2 - (Server.notebooks * 0.1)
	if apple > 0.0:
		apple -= delta
		if apple <= 0.0: slap_effect(true)
	if has_node(locker) or apple > 0.0:
		slap_buffer = 0.0
		slap_interval = SLAP_INTERVAL
		velocity = Vector3.ZERO
		move_and_slide()
		return
	slap_buffer -= delta
	if slap_interval > 0.0: slap_interval -= delta
	if slapping and slap_interval <= 0.0:
		slap_buffer = SLAP_BUFFER
		slap_interval = SLAP_INTERVAL
		slap_effect.rpc()
	if slap_buffer > 0.0:
		var direction := (transform.basis * Vector3.FORWARD).normalized()
		velocity = direction * SPEED
	else:
		velocity = Vector3.ZERO

	move_and_slide()

var locker: NodePath = NodePath("")
@rpc("any_peer", "call_local", "reliable")
func inspect_locker(path):
	if !is_multiplayer_authority(): return
	if locker: return
	if !has_node(path): return
	if get_node(path).global_position.distance_squared_to(global_position) > reach_squared():
		return
	locker = path
	$InspectLockerTimer.start()
	check_locker.rpc()
	await $InspectLockerTimer.timeout
	var player = Server.get_type_instance(Server.TYPE.PLAYER)
	if player and player.locker == locker:
		player.exit_locker.rpc_id(1)
	locker = NodePath("")
	slap_effect.rpc(true)

@rpc("authority", "call_local", "reliable")
func check_locker():
	$InspectLockerSound.play()
	$Sprite.play("talk")

@rpc("authority", "call_local", "reliable")
func slap_effect(ruler: bool = false):
	if ruler:
		$Sprite.play("ruler")
		return
	$Sprite.play("slap")
	$SlapSound.play()

@rpc("authority", "call_local", "reliable")
func get_apple():
	$Sprite.animation = "apple"
	$ThankAppleSound.play()
	
func _process(_delta: float) -> void:
	if apple > 0.0:
		if apple <= 10.0:
			if $EatSound/Timer.is_stopped():
				$EatSound/Timer.start()
			if !$Sprite.is_playing(): $Sprite.play("apple")
		else:
			$Sprite.animation = "apple"
	else:
		$EatSound/Timer.stop()


	if multiplayer.get_unique_id() != id: return
	var v = remap(slap_interval, SLAP_INTERVAL, 0.0, $UI/Stamina/Start.position.x - 96.0, $UI/Stamina/End.position.x)
	var tween = create_tween().set_trans(Tween.TRANS_SINE)
	var y = $UI/Stamina/Needle.position.y
	tween.tween_property($UI/Stamina/Needle, "position", Vector2(v, y), 0.1)
		
	$UI.show()
	
	var obj = $Camera/InteractRay.get_collider()
	if  apple <= 0.0 and obj and obj.is_in_group("interact"):
		$UI/Hand.show()
		if Input.is_action_just_pressed("click"):
			if obj.is_in_group("blue_locker"):
				inspect_locker.rpc_id(1, obj.get_path())

	else: $UI/Hand.hide()

func reach_squared() -> float:
	var v = (-$Camera/InteractRay.target_position.z + 1.0)
	return v * v

@onready var player_hightlight = preload("res://characters/baldi/player_highlight.tscn")
@rpc("authority", "call_local", "reliable")
func spawn_highlight(player_position: Vector3, loudness: float):
	# Is not baldi owner
	if Server.anti_hearing_active: return
	if multiplayer.get_unique_id() != id:
		push_error("Spawn highlight invoked for non baldi owner")
		return
	
	
	var inst = player_hightlight.instantiate()
	inst.loudness = loudness
	$Highlights.add_child(inst)
	inst.global_position = player_position

func _on_eat_sound_timeout() -> void:
	$EatSound.play()
