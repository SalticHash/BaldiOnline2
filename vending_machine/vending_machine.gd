extends Area3D

# Materials
@onready var bsoda_material: StandardMaterial3D = preload("res://vending_machine/bsoda_material.tres")
@onready var bsoda_out_material: StandardMaterial3D = preload("res://vending_machine/bsoda_out_material.tres")
@onready var bsoda_crazy_material: StandardMaterial3D = preload("res://vending_machine/bsoda_crazy_material.tres")
@onready var zesty_material: StandardMaterial3D = preload("res://vending_machine/zesty_material.tres")
@onready var zesty_out_material: StandardMaterial3D = preload("res://vending_machine/zesty_out_material.tres")
@onready var zesty_crazy_material: StandardMaterial3D = preload("res://vending_machine/zesty_crazy_material.tres")
@onready var diet_material: StandardMaterial3D = preload("res://vending_machine/diet_material.tres")
@onready var diet_out_material: StandardMaterial3D = preload("res://vending_machine/diet_out_material.tres")

@export_enum("bsoda", "zesty", "diet") var type: String = "bsoda"
@export var crazy: bool = false

var uses: int = 1
func _ready() -> void:
	if crazy:
		if type == "diet": type = "bsoda"
		$Faceplate.material_override = bsoda_crazy_material if type == "bsoda" else zesty_crazy_material
		uses = 10
		return
	match type:
		"bsoda": $Faceplate.material_override = bsoda_material
		"zesty": $Faceplate.material_override = zesty_material
		"diet": $Faceplate.material_override = diet_material
	
	(bsoda_material if type == "bsoda" else zesty_material)

func use() -> void:
	if !is_multiplayer_authority(): return
	if uses <= 0: return
	uses -= 1
	use_sound.rpc()
	if uses == 0:
		used_up.rpc()

@rpc("authority", "call_local", "reliable")
func used_up() -> void:
	match type:
		"bsoda": $Faceplate.material_override = bsoda_out_material
		"zesty": $Faceplate.material_override = zesty_out_material
		"diet": $Faceplate.material_override = diet_out_material

@rpc("authority", "call_local", "reliable")
func use_sound() -> void:
	$Sound.play()

func get_item_id() -> int:
	if crazy: return randi_range(2, 6) #TODO FIX WITH MISSING IDs
	return 2 if type == "bsoda" else 3
