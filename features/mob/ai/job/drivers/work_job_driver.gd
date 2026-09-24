class_name WorkJobDriver
extends JobDriver

var movement: Movement
var grid: Grid
var _work_capability: WorkerCapability
var _move_started := false
var _working := false
var _travel_elapsed := 0.0

const MAX_TRAVEL_DURATION := 60.0


func configure(
	p_movement: Movement,
	p_grid: Grid,
) -> void:
	movement = p_movement
	grid = p_grid


func start() -> Status:
	var work_job := job as WorkJob
	if (
		work_job == null
		or movement == null
		or grid == null
		or consumer == null
		or consumer.actor == null
		or consumer.capability == null
		or not consumer.capability.can_perform(work_job.work_type)
		or not _is_machine_need(work_job)
	):
		return Status.FAILURE
	# Work ports use capability identity to track their current worker.
	# Give each worker its own copy even when NPCs share a definition resource.
	_work_capability = consumer.capability.duplicate() as WorkerCapability
	return Status.RUNNING if _work_capability != null else Status.FAILURE


func tick(delta: float) -> Status:
	var work_job := job as WorkJob
	if (
		work_job == null
		or work_job.machine == null
		or not is_instance_valid(work_job.machine)
		or work_job.machine.is_queued_for_deletion()
	):
		return Status.FAILURE

	if _working:
		if _actor_cell() != work_job.destination:
			return Status.FAILURE
		if work_job.machine.is_shut_down:
			return Status.FAILURE
		if not work_job.machine.is_working_at_port(
			work_job.destination,
			_work_capability,
		):
			# The machine clears its occupied ports when processing finishes.
			return Status.SUCCESS
		return Status.RUNNING

	if not _is_machine_need(work_job):
		return Status.FAILURE
	if _actor_cell() == work_job.destination:
		movement.stop_moving()
		if not work_job.machine.try_working_at_port(
			work_job.destination,
			_work_capability,
		):
			return Status.FAILURE
		_working = true
		return Status.RUNNING

	_travel_elapsed += delta
	if _travel_elapsed > MAX_TRAVEL_DURATION:
		return Status.FAILURE
	if not _move_started:
		var target := grid.cell_to_world(work_job.destination)
		target.y = consumer.actor.global_position.y
		movement.start_moving_to(target)
		_move_started = true
	if movement.status != Movement.Status.MOVING:
		return Status.FAILURE
	return Status.RUNNING


func cancel() -> void:
	var work_job := job as WorkJob
	if (
		_working
		and work_job != null
		and work_job.machine != null
		and is_instance_valid(work_job.machine)
		and work_job.machine.is_working_at_port(
			work_job.destination,
			_work_capability,
		)
	):
		work_job.machine.try_unallocate_working_port(
			work_job.destination,
			_work_capability,
		)
	_working = false
	if movement != null:
		movement.stop_moving()


func _is_machine_need(work_job: WorkJob) -> bool:
	if (
		work_job == null
		or work_job.machine == null
		or not is_instance_valid(work_job.machine)
	):
		return false
	for need in work_job.machine.get_remaining_work_needs():
		if (
			need.cell == work_job.destination
			and need.work_type == work_job.work_type
		):
			return true
	return false


func _actor_cell() -> Vector3i:
	var cell := grid.world_to_cell(consumer.actor.global_position)
	cell.y = 0
	return cell
