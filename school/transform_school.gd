@tool
extends Node3D

@export var move: Vector3
@export_tool_button("Move") var _move = move_func
func move_func():
	for c in get_children():
		c.position += move
