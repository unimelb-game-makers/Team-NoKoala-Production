@tool
extends BTAction

func _generate_name() -> String:
	return "FollowPlayer"

func _tick(_delta: float) -> Status:
	if blackboard.has_var(Brain.LAST_KNOWN_PLAYER_POSITION):
		var player_position: Vector3 = blackboard.get_var(Brain.LAST_KNOWN_PLAYER_POSITION)
		blackboard.set_var(Brain.TARGET_POSITION, player_position)
		return Status.SUCCESS
	else:
		return Status.FAILURE
