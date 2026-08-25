@tool
extends BTCondition

var world_state: WorldState

@export var start_seconds: float
@export var end_seconds: float

func _generate_name() -> String:
	return "In Game Time Range"

func _setup() -> void:
	world_state = scene_root.get_tree().get_first_node_in_group("world_state")

func _tick(_delta: float) -> Status:
	if world_state.game_time_seconds >= start_seconds \
	and world_state.game_time_seconds <= end_seconds:
		return SUCCESS
	else:
		return FAILURE
