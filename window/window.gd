extends StaticBody3D

@onready var wood_mesh = preload("res://window/wood_mesh.tres")
@onready var green_mesh = preload("res://window/green_mesh.tres")
@export_enum("normal", "faculty") var window_front: String = "normal"
@export_enum("normal", "faculty") var window_back: String = "normal"

@export var front_material: Material
@export var back_material: Material

func _ready() -> void:
	$Mesh/Front.mesh = green_mesh if window_front == "normal" else wood_mesh
	$Mesh/Front.material_override = front_material
	$Sprites/Front.animation = window_front + "_normal"
	
	$Mesh/Back.mesh = green_mesh if window_back == "normal" else wood_mesh
	$Mesh/Back.material_override = back_material
	$Sprites/Back.animation = window_back + "_normal"
