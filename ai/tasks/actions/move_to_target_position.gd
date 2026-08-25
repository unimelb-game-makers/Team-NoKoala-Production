@tool
extends BTAction

@export var move_speed: float = 1.0
@export var rotation_speed := 5.0
@export var stop_distance: float = 1.0

func _generate_name() -> String:
	return "MoveToTargetPosition"

func _tick(delta: float) -> Status:
	var target_position = blackboard.get_var(Brain.TARGET_POSITION)
	if target_position == null:
		return Status.FAILURE

	if scene_root.global_position.distance_to(target_position) <= stop_distance:
		return Status.SUCCESS

	var position = scene_root.global_position
	position = position.move_toward(target_position, move_speed * delta)
	scene_root.global_position = position
	
	var direction = target_position - position
	direction.y = 0
	
	if direction.length_squared() > 0.001:
		var target_angle = atan2(direction.x, direction.z) + PI
		scene_root.rotation.y = lerp_angle(
			scene_root.rotation.y,
			target_angle,
			rotation_speed * delta
		)

	return Status.RUNNING
