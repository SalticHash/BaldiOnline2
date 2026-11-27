extends CharacterBody3D

var popped: bool = false
var player: Node3D = null
var can_grab: bool = true
@export var value: int = 0 :
	set(v):
		value = v
		$Sprite.animation = str(v)

var min_wander_time: float = 2.5
var max_wander_time: float = 10.0
var speed: float = 0.1
var wander_time: float = 0.0
var dir: Vector3 = Vector3.ZERO
var hovered: bool = false

func _ready() -> void:
	$Label3D.text = str(value)
	if !is_multiplayer_authority(): return
	$Bounce.area_entered.connect(bounce)

func bounce(balloon: Node3D):
	var normal = balloon.global_position.direction_to(global_position)
	normal.y = 0.0
	normal = normal.normalized()
	if normal.is_equal_approx(Vector3.ZERO):
		return
	
	dir = dir.bounce(normal).normalized()

func change_dir():
	var a = randf_range(0.0, TAU)
	dir = Vector3(sin(a), 0, cos(a))
	wander_time = randf_range(min_wander_time, max_wander_time)

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	if popped: return
	wander_time -= delta
	if !player: move(delta)
	else: grabbed_move()

func _process(delta: float) -> void:
	$Sprite.offset.y = move_toward(
		$Sprite.offset.y,
		-55.0 if hovered else 0.0,
		555.0 * delta
	)

func move(delta) -> void:
	if wander_time <= 0.0: change_dir()
	velocity = dir * speed
	var c = move_and_collide(velocity * delta)
	if c: dir = dir.bounce(c.get_normal()).normalized()
	position.y = 0.0
	
func grabbed_move() -> void:
	var a = -player.rotation.y - PI/2
	var player_dir = (transform.basis * Vector3(cos(a), 0.0, sin(a))).normalized()
	global_position = \
		player.global_position + (player_dir * 0.25) - Vector3(0, 0.5, 0)


func grab(new_player: Node3D):
	if !is_multiplayer_authority(): return
	if !can_grab: return
	if player: return
	player = new_player

func release():
	if !is_multiplayer_authority(): return
	player = null

var spawn_pos: Vector3
func pop(new_position: Vector3, restore: bool = true):
	if !is_multiplayer_authority(): return
	if popped or removed:
		if !restore: $PopTimer.stop()
		return
	release()
	spawn_pos = new_position
	update.rpc(&"pop")
	if restore: $PopTimer.start()

var removed: bool = false
func remove():
	if !is_multiplayer_authority(): return
	release()
	removed = true
	update.rpc(&"remove")

func _on_pop_timer_timeout() -> void:
	position = spawn_pos
	update.rpc(&"restore")

@rpc("authority", "call_local", "reliable")
func update(effect: StringName) -> void:
	match effect:
		&"no_interact":
			can_grab = false
			$Collision.set_deferred(&"disabled", true)
		&"pop":
			popped = true
			can_grab = false
			$Sprite.play("pop")
			$Collision.set_deferred(&"disabled", true)
			$Pop.play()
		&"restore":
			popped = false
			$Collision.set_deferred(&"disabled", false)
			can_grab = true
			$Sprite.animation = str(value)
		&"remove":
			popped = true
			$Collision.set_deferred(&"disabled", true)
			can_grab = false
			$Sprite.hide()
