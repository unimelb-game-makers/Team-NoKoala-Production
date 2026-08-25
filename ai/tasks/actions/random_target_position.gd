@tool
extends BTAction

@export var radius: float = 10

func _generate_name() -> String:
	return "RandomTargetPosition"

func _tick(_delta: float) -> Status:
	var theta: float = randf() * 2 * PI
	var random_radius: float = sqrt(randf()) * radius
	var offset = Vector3(cos(theta) * random_radius, 0, sin(theta) * random_radius)
	var position = scene_root.global_position + offset
	blackboard.set_var(Brain.TARGET_POSITION, position)
	return Status.SUCCESS
