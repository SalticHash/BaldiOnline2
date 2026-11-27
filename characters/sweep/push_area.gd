extends Area3D

@onready var p = get_parent()

func _ready() -> void:
	if !is_multiplayer_authority(): return
	body_exited.connect(_body_exited)
	body_entered.connect(_body_entered)

func _body_exited(body: Node3D):
	body.override_velocity = null

func _body_entered(body: Node3D) -> void:
	if body == p: return
	body.override_velocity = p
	play_sound.rpc()

@rpc("authority", "call_local", "reliable")
func play_sound():
	$gotta_sweep.play()
