@tool
extends MeshInstance3D
#### TS IS AI, DONT TOUCH IT
@export_tool_button("Generate Mesh")
var generate_button = generate_mesh

var polygon := PackedVector2Array([
	Vector2(-1, -1),
	Vector2(-1, 1),
	Vector2(1, 1),
	Vector2(1, -1),
	Vector2(0.75, -1),
	Vector2(0.75, 0.65),
	Vector2(-0.75, 0.65),
	Vector2(-0.75, -0.35),
	Vector2(0.75, -0.35),
	Vector2(0.75, -1)
])

func generate_mesh():
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()

	for point in polygon:
		vertices.append(Vector3(point.x, -point.y, 0))

		uvs.append(Vector2(
			(point.x + 1.0) / 2.0,
			(point.y + 1.0) / 2.0
		))

	var indices := Geometry2D.triangulate_polygon(polygon)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	var new_mesh := ArrayMesh.new()
	new_mesh.add_surface_from_arrays(
		Mesh.PRIMITIVE_TRIANGLES,
		arrays
	)

	mesh = new_mesh
