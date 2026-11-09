extends Area3D

@export var front_material: Material
@export var back_material: Material
var open: bool = false

func _ready() -> void:
	$Meshes/Front.material_override = front_material
	$Meshes/Back.material_override = back_material

func _process(_delta: float) -> void:
	$Sprites/Back.play("open" if open else "close")
	$Sprites/Front.play("open" if open else "close")
	
	if !is_multiplayer_authority(): return
	if has_overlapping_bodies():
		if !open: play_sound.rpc()
		open = true
		$Timer.start()

func _on_timer_timeout() -> void:
	if !is_multiplayer_authority(): return
	open = false

@rpc("authority", "call_local", "reliable")
func play_sound():
	$Sound.play()
