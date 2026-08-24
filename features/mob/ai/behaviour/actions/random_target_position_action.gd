class_name RandomTargetPositionAction
extends Action

@export var radius: float = 10

func _on_start(brain: Brain) -> Status:
	var theta: float = randf() * 2 * PI
	var random_radius: float = sqrt(randf()) * radius
	var offset = Vector3(cos(theta) * random_radius, 0, sin(theta) * random_radius)
	var position = brain.actor.global_position + offset
	brain.remember_memory_value(Brain.MemoryModuleType.TARGET_POSITION, position)
	return Status.SUCCESS
