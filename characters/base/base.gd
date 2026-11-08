extends CharacterBody3D
class_name BaseController

var id: int = 0
const SPEED: float = 60.0
var username: String = ""
@onready var camera: Camera3D = $Camera

func _enter_tree() -> void:
	$InputSync.set_multiplayer_authority(id)

func _ready() -> void:
	position.x += randf_range(-1, 1)
	position.z += randf_range(-1, 1)
	$NameLabel.text = username
