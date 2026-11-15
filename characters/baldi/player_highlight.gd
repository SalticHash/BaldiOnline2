extends Node3D

var loudness: float
var max_lifetime: float
var lifetime: float

func _ready() -> void:
	max_lifetime = remap(loudness, 0, 127, 2.5, 30.0)
	lifetime = max_lifetime


func _process(delta: float) -> void:
	if lifetime <= 0.0:
		queue_free()
		return
	lifetime -= delta
	
	var s: StandardMaterial3D = $Mesh.material_override
	s.albedo_color.a = remap(lifetime, max_lifetime, 0.0, 0.8, 0.0)
