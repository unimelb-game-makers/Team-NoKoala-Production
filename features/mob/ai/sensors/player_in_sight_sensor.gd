class_name PlayerPositionSensor
extends Sensor

var vision: MobVision
var player: Node3D

func _get_player(brain: Brain):
	var nodes := brain.actor.get_tree().get_nodes_in_group("player")
	if nodes.size() > 0:
		return nodes[0]
	else:
		return null

func _on_start(brain: Brain) -> void:
	vision = NodeUtils.get_child_by_type(brain.actor, MobVision)
	player = _get_player(brain)

func _on_process(brain: Brain, _delta: float) -> void:
	# TODO: Remove this when we have a stable scene loading order
	if player == null:
		player = _get_player(brain)

	if vision.is_in_sight(player):
		brain.remember_memory_value(Brain.LAST_KNOWN_PLAYER_POSITION, player.global_position)
