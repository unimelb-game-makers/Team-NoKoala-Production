class_name WanderJobDriver
extends JobDriver

var movement: Movement
var destination: Vector3
var move_started: bool = false


func start() -> Status:
	movement = NodeUtils.get_child_by_type(consumer.actor, Movement)
	var theta: float = randf() * 2 * PI
	var random_radius: float = sqrt(randf()) * (job as WanderJob).radius
	var offset = Vector3(cos(theta) * random_radius, 0, sin(theta) * random_radius)
	destination = consumer.actor.global_position + offset
	return Status.RUNNING


func tick(_delta: float) -> Status:
	if not move_started:
		if movement.within_stop_distance(destination):
			return Status.SUCCESS
		else:
			movement.start_moving_to(destination)
			move_started = true
			return Status.RUNNING

	if movement.status == Movement.Status.FAILED:
		return Status.FAILURE

	if movement.status == Movement.Status.STOPPED:
		if movement.within_stop_distance(destination):
			return Status.SUCCESS
		else:
			return Status.FAILURE
	else:
		return Status.RUNNING
