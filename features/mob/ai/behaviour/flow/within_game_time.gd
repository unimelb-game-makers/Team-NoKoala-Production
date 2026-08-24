class_name WithinGameTime
extends ConditionNode

@export var start_second: float
@export var end_second: float

var world_state: WorldState

func _on_start(brain: Brain) -> Status:
	world_state = brain.actor.get_tree().get_nodes_in_group("world_state")[0]
	return Status.RUNNING

func _check(_brain: Brain) -> bool:
	var seconds := world_state.game_time_seconds
	return seconds >= start_second and seconds <= end_second
