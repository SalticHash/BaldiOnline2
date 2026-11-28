extends BaseController

const SPEED: float = 1.0#7.5 #TODO FIX

var slapping: bool = false
var slap_buffer: float = 0.0
var slap_interval: float = 0.0
const SLAP_BUFFER: float = 0.167 #10 frames in a 60fps game
var SLAP_INTERVAL: float = 2.0
var apple: float = 0.0
var praise_time: float = 0.0
var anger: float = 0.0
func _physics_process(delta: float) -> void:

	if !is_multiplayer_authority(): return
	super(delta)
	if anger > 0.0: anger -= delta / 8.0
	if $Area.has_overlapping_bodies() and !has_node(locker) and apple <= 0.0 and praise_time <= 0.0:
		for b in $Area.get_overlapping_bodies():
			if b.lost: break
			var i = b.has_item(b.ITEM.APPLE)
			if i != -1:
				b.set_item(i, b.ITEM.NONE)
				apple = 15.0
				get_apple.rpc()
				break
			b.lose(self)
	
	SLAP_INTERVAL = 1.0 - (Server.notebooks * 0.1) / remap(anger, 0.0, 1.0, 1.0, 2.0)
	if apple > 0.0 and praise_time < 0.0:
		apple -= delta
		if apple <= 0.0: slap_effect.rpc(true)
	if praise_time > 0.0:
		praise_time -= delta
		if praise_time <= 0.0:
			slap_effect.rpc(true)
	if has_node(locker) or apple > 0.0 or praise_time > 0.0:
		slap_buffer = 0.0
		slap_interval = SLAP_INTERVAL
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return
	if !jumping_rope: move(delta)
	else: velocity = Vector3(0, velocity.y, 0)
	
	if override_velocity:
		velocity = override_velocity.velocity * 0.99 + velocity * 0.3
	move_and_slide()
	global_position.y = max(global_position.y, 0.0)

func move(delta: float):
	slap_buffer -= delta
	#TODO FIX
	if slap_interval > 0.0: slap_interval -= delta
	#if slapping and slap_interval <= 0.0:
		#slap_buffer = SLAP_BUFFER
		#slap_interval = SLAP_INTERVAL
		#slap_effect.rpc()
	if true:#slap_buffer > 0.0:
		var direction := (transform.basis * Vector3.FORWARD).normalized()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = 0
		velocity.z = 0

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

@rpc("authority", "call_local", "reliable")
func praise_effect(num: int):
	$PraiseSounds.get_child(num).play()
	$Sprite.play("talk")

func bad_math():
	anger += 1.0
	return
	print("ANGRY")

func praise(activity: StringName):
	if !is_multiplayer_authority(): return
	return
	match activity:
		&"math":
			praise_effect.rpc(randi_range(0, 5))
			praise_time += 5.0
func _process(delta: float) -> void:
	super(delta)
	if praise_time > 0.0:
		if !$Sprite.is_playing(): $Sprite.play("talk")
	if apple > 0.0 and praise_time <= 0.0:
		if apple <= 10.0:
			if $EatSound/Timer.is_stopped():
				$EatSound/Timer.start()
			if !$Sprite.is_playing(): $Sprite.play("apple")
		else:
			$Sprite.animation = "apple"
	else:
		$EatSound/Timer.stop()


	if multiplayer.get_unique_id() != id: return
	$UI/Stamina.value = remap(slap_interval, 0.0, SLAP_INTERVAL, 1.0, 0.0)
	$UI.show()
	
	var obj = $Camera/InteractRay.get_collider()
	if  apple <= 0.0 and praise_time <= 0.0 and obj and obj.is_in_group("interact") and obj.get_meta(&"interact_id") == &"blue_locker":
		$UI/Hand.show()
		if Input.is_action_just_pressed("click"):
			inspect_locker.rpc_id(1, obj.get_path())
	else: $UI/Hand.hide()

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
