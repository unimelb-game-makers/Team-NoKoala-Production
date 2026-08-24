class_name FollowPlayerAction
extends Action

func _on_start(brain: Brain) -> Status:
	var player_position = brain.get_memory_value(Brain.MemoryModuleType.LAST_KNOWN_PLAYER_POSITION)
	if player_position == null:
		return Status.FAILURE
	else:
		brain.remember_memory_value(Brain.MemoryModuleType.TARGET_POSITION, player_position)
		return Status.SUCCESS

func _on_process(_brain: Brain, _delta: float) -> Status:
	return Status.SUCCESS
