extends CharacterBody3D
class_name BaseController

var id: int = 0
var username: String = ""
@onready var camera: Camera3D = $Camera

func _enter_tree() -> void:
	$InputSync.set_multiplayer_authority(id)
	$PeerSync.set_multiplayer_authority(id)
	$InputSync.set_visibility_for(1, true)
	$NameLabel.text = username
