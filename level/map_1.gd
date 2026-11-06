extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var id = multiplayer.get_unique_id()
	if id == 1:
		$Camera3D.make_current()
		get_window().size = Vector2(716, 698)
		get_window().position = Vector2(1844, 54)
	else:
		$Camera3D2.make_current()
		get_window().size = Vector2(716, 698)
		get_window().position = Vector2(1844, 810)
	multiplayer.server_disconnected.connect(func():
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
		get_tree().change_scene_to_file("res://multiplayer/multiplayer.tscn")
	)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		$Door.open_door.rpc_id(1)
