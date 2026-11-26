extends Area3D

var pulled_down: bool = false
@export var block: Node3D
func _ready() -> void:
	if !is_multiplayer_authority(): return
	body_entered.connect(func(body):
		if !body.is_in_group("player"): return
		if pulled_down: return
		pulldown.rpc()
	)
		

@rpc("authority", "call_local", "reliable")
func pulldown():
	if pulled_down or Server.exits == 3 or Server.notebooks < 7: return
	Server.exits += 1
	pulled_down = true
	block.position.y += 1
	$CloseSound.play()
