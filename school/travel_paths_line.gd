@tool
extends Node3D

@export var mat1: StandardMaterial3D
@export var mat2: StandardMaterial3D
@export var mesh: MeshInstance3D
@export_tool_button("Create lines") var c = _c
func _c():
	var scene_root := get_tree().edited_scene_root
	for path: Path3D in get_children():
		var old = path.get_node_or_null("Line")
		if old:
			path.remove_child(old)
			old.queue_free()
		continue
		var line = CSGPolygon3D.new()
		line.name = "Line"
		var s = 0.5
		line.polygon = PackedVector2Array([
			Vector2(-s, 0.0),
			Vector2(s, 0.0),
			Vector2(s, -0.1),
			Vector2(-s, -0.1)
		])
		line.material = mat1
		line.path_interval = 0.5
		line.mode = CSGPolygon3D.MODE_PATH
		line.path_local = true
		line.path_node = NodePath("..")
		path.add_child(line)
		line.owner = scene_root
		
		var start = mesh.duplicate()
		start.name = "Start"
		start.show()
		start.global_position = path.curve.sample(0, 0.0)
		start.owner = scene_root
		line.add_child(start)
		if !path.curve.closed:
			var end = mesh.duplicate()
			end.name = "End"
			end.show()
			end.global_position = path.curve.sample(path.curve.point_count, 0.0)
			line.add_child(end)
			end.owner = scene_root
