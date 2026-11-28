extends Node
var players: Dictionary = {}

const MAX_ITEM = 10
var anti_hearing: float = 0.0 :
	set(value):
		anti_hearing = value
		anti_hearing_active = anti_hearing > 0.0

var anti_hearing_active: bool = false

func _process(delta: float) -> void:
	if !multiplayer.has_multiplayer_peer() or !is_multiplayer_authority(): return
	if anti_hearing > 0.0: anti_hearing -= delta

var notebooks: int = 0
var exits: int = 0
const GROUPS: Array[StringName] = [&"player", &"baldi", &"student", &"playtime"]
enum TYPE {
	PLAYER,
	BALDI,
	STUDENT,
	PLAYTIME
}
func get_type_id(type: int) -> int:
	for player_id in players.keys():
		var player = players.get(player_id)
		if player.get("type") == type:
			return player_id
	return -1

func get_id_type(id: int) -> int:
	return players.get(id).get("type")
	
func get_type_instance(type: int) -> Node3D:
	var id = get_type_id(type)
	return get_id_instance(id)

func get_id_instance(id: int) -> Node3D:
	if id == -1:
		push_warning("Invalid ID for get_id_instance")
		return null
	return get_node("/root/Game/World/Players").get_node(str(id))

func rpc_type(type: TYPE, method: StringName, ...args: Array) -> void:
	for g in get_tree().get_nodes_in_group(GROUPS[type]):
		g.callv(&"rpc_id", [g.id, method] + args)

func get_closest(type: TYPE, pos: Vector3) -> Array:
	var closest: Node3D = null
	var dist: float = INF
	for g: Node3D in get_tree().get_nodes_in_group(GROUPS[type]):
		var d = g.global_position.distance_squared_to(pos)
		if d < dist:
			dist = d
			closest = g
	return [closest, dist]

func get_player_reach() -> float:
	var longest: float = 0.0
	for g: Node3D in get_tree().get_nodes_in_group(&"player"):
		longest = max(g.reach_squared(), longest)
	return longest


func alert_baldi(noise: int, player: Node3D, position: Vector3 = Vector3.INF):
	if position == Vector3.INF: position = player.global_position
	rpc_type(Server.TYPE.BALDI, "spawn_highlight", position, noise)
