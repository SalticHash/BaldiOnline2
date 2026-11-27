extends Area3D

@onready var default_material: StandardMaterial3D = preload("res://activity/math_machine/default_material.tres")
@onready var right_material: StandardMaterial3D = preload("res://activity/math_machine/right_material.tres")
@onready var wrong_material: StandardMaterial3D = preload("res://activity/math_machine/wrong_material.tres")
@onready var notebook: PackedScene = preload("res://notebook/notebook.tscn")
var a: int = -1
var b: int = -1
var sum: bool = false
var result: int = -1
func _ready() -> void:
	if is_multiplayer_authority(): generate(randf() > 0.5)

func _process(_delta: float) -> void:
	$Num1.text = str(a)
	$Num2.text = str(b)
	$Op.text = "+" if sum else "-"
	$Result.text = str(result)

func generate(is_sum: bool) -> void:
	sum = is_sum
	var t1 = randi_range(0, 9)
	var t2 = randi_range(0, 9)
	if sum:
		result = max(t1, t2)
		a = min(t1, t2)
		b = result - a
		if (a + b) != result:
			push_error("%d + %d = %d" % [a, b, result])
	else:
		a = max(t1, t2)
		b = min(t1, t2)
		result = a - b
		if (a - b) != result:
			push_error("%d - %d = %d" % [a, b, result])

var solved: bool = false
func solve(balloon: Node3D) -> void:
	if !is_multiplayer_authority(): return
	if balloon.get_node_or_null(^"../..") != get_parent(): return
	if solved: return
	solved = true
	print(balloon.value, result)
	if balloon.value == result:
		var player = balloon.player
		if player.stamina < 1.0: player.stamina = 1.0
		get_tree().call_group(&"baldi", &"praise", &"math")
		set_state.rpc(true)
	else:
		set_state.rpc(false)
		get_tree().call_group(&"baldi", &"bad_math")
		Server.alert_baldi(126, $SP.global_position)
	balloon.remove()
	var inst = notebook.instantiate()
	inst.color = randi_range(0, 6)
	$NotebookSpawn.add_child(inst, true)
	get_parent().pop_balloons()

@rpc("authority", "call_local", "reliable")
func set_state(correct: bool):
	$Result.text = str(result)
	if correct:
		$Correct.play()
		$Mesh.material_override = right_material
	else:
		$Incorrect.play()
		$Mesh.material_override = wrong_material
