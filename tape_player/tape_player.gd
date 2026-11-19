extends Area3D

@export var phone: bool = false
var cooldown: float = 0.0 :
	set(value):
		cooldown = value
		open = cooldown <= 0.0

var open: bool = true
func _process(delta: float) -> void:
	if !phone: $Sprite.play("open" if open else "closed")
	if !is_multiplayer_authority(): return
	if cooldown > 0.0: cooldown -= delta

func anti_hearing():
	if !is_multiplayer_authority(): return
	if cooldown > 0.0 and !phone: return
	if !phone: cooldown = 30
	Server.anti_hearing = 30.0
	play_sound.rpc()

func funtime():
	if !is_multiplayer_authority(): return
	if phone: return
	cooldown = 65
	play_sound.rpc(true)

@rpc("authority", "call_local", "reliable")
func play_sound(song: bool = false):
	if song and !phone:
		$Song.play()
	$Sound.play()
