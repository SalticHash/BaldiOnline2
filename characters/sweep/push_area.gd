extends Area3D

@onready var p = get_parent()

func _ready() -> void:
	if !is_multiplayer_authority(): return
	body_exited.connect(_body_exited)

func _physics_process(_delta: float) -> void:
	if !is_multiplayer_authority(): return
	for body in get_overlapping_bodies():
		if body == p: continue
		body.override_velocity = p.direction.normalized() * p.SPEED_SWEEP

func _body_exited(body: Node3D):
	body.override_velocity = Vector3.ZERO
	
