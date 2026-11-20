extends Area3D

# Materials
@onready var bsoda_material: StandardMaterial3D = preload("res://vending_machine/bsoda_material.tres")
@onready var bsoda_out_material: StandardMaterial3D = preload("res://vending_machine/bsoda_out_material.tres")
@onready var bsoda_crazy_material: StandardMaterial3D = preload("res://vending_machine/bsoda_crazy_material.tres")
@onready var zesty_material: StandardMaterial3D = preload("res://vending_machine/zesty_material.tres")
@onready var zesty_out_material: StandardMaterial3D = preload("res://vending_machine/zesty_out_material.tres")
@onready var zesty_crazy_material: StandardMaterial3D = preload("res://vending_machine/zesty_crazy_material.tres")

@export_enum("bsoda", "zesty") var type: String = "bsoda"
@export var crazy: bool = false

var uses: int = 1
func _ready() -> void:
	if crazy: uses = 10
	$Faceplate.material_override = \
	(bsoda_crazy_material if type == "bsoda" else zesty_crazy_material) if crazy else \
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
	$Faceplate.material_override = (bsoda_out_material if type == "bsoda" else zesty_out_material)

@rpc("authority", "call_local", "reliable")
func use_sound() -> void:
	$Sound.play()

func get_item_id() -> int:
	if crazy: return randi_range(1, 6) #TODO FIX WITH MISSING IDs
	return 1 if type == "bsoda" else 2
