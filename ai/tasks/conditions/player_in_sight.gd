@tool
extends BTCondition

var vision: MobVision
var player: Node3D

func _generate_name() -> String:
	return "Player In Sight"

func _setup() -> void:
	vision = NodeUtils.get_child_by_type(scene_root, MobVision)
	player = scene_root.get_tree().get_first_node_in_group("player")

func _tick(_delta: float) -> Status:
	if player == null:
		# TODO: Remove this
		player = scene_root.get_tree().get_first_node_in_group("player")

	if vision.is_in_sight(player):
		return SUCCESS
	else:
		return FAILURE
