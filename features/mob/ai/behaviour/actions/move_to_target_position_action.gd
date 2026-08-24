class_name MoveToTargetPositionAction
extends Action

@export var move_speed: float = 1.0
@export var rotation_speed := 5.0
@export var stop_distance: float = 1.0

func _on_start(_brain: Brain) -> Status:
	return Status.RUNNING

func _on_process(brain: Brain, delta: float) -> Status:
	var target_position = brain.get_memory_value(Brain.MemoryModuleType.TARGET_POSITION)
	if target_position == null:
		return Status.FAILURE

	if brain.actor.global_position.distance_to(target_position) <= stop_distance:
		return Status.SUCCESS

	var position = brain.actor.global_position
	position = position.move_toward(target_position, move_speed * delta)
	brain.actor.global_position = position
	
	var direction = target_position - position
	direction.y = 0
	
	if direction.length_squared() > 0.001:
		var target_angle = atan2(direction.x, direction.z) + PI
		brain.actor.rotation.y = lerp_angle(
			brain.actor.rotation.y,
			target_angle,
			rotation_speed * delta
		)

	return Status.RUNNING
