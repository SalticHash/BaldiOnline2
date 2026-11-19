extends Area3D

@export var front_material: Material
@export var back_material: Material
var open: bool = false
var locked: bool = false
func _ready() -> void:
	$Meshes/Front.material_override = front_material
	$Meshes/Back.material_override = back_material

func _physics_process(_delta: float) -> void:
	var anim = "lock" if locked else "open" if open else "close"
	$Sprites/Back.play(anim)
	$Sprites/Front.play(anim)
	
	$Solid/Collision.disabled = !locked
	if !is_multiplayer_authority(): return
	if has_overlapping_bodies() and !locked:
		if !open: play_sound.rpc()
		open = true
		$Timer.start()

func _on_timer_timeout() -> void:
	if !is_multiplayer_authority(): return
	open = false

@rpc("authority", "call_local", "reliable")
func play_sound():
	$Sound.play()

@rpc("authority", "call_local", "reliable")
func lock():
	$LockSound.play()
	
	open = false
	locked = true
	$LockTimer.start()
	

func _on_body_entered(body: Node3D) -> void:
	if !is_multiplayer_authority(): return
	if !body.is_in_group("player"): return
	if open: return
	
	Server.alert_baldi(10)


func _on_lock_timer_timeout() -> void:
	locked = false
