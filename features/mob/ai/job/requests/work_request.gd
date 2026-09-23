class_name WorkRequest
extends JobRequest

var work_type: WorkType.Value
var destination: Vector3i
var machine: BasicMachine
var _factory_manager: FactoryManager
var _reservation_manager: ReservationManager


func _init(
	p_work_type: WorkType.Value,
	p_destination: Vector3i,
	p_factory_manager: FactoryManager,
	p_reservation_manager: ReservationManager,
	p_machine: BasicMachine,
) -> void:
	work_type = p_work_type
	destination = p_destination
	machine = p_machine
	_factory_manager = p_factory_manager
	_reservation_manager = p_reservation_manager


func job_type() -> StringName:
	return WorkJob.JOB_TYPE


func equals(other: JobRequest) -> bool:
	var work := other as WorkRequest
	return (
		work != null
		and work.work_type == work_type
		and work.destination == destination
		and work.machine == machine
		and work._factory_manager == _factory_manager
	)


func can_assign(consumer: JobConsumer) -> bool:
	return (
		super(consumer)
		and _consumer_can_work(consumer)
		and _is_needed()
		and _destination_is_available()
	)


func score(consumer: JobConsumer) -> float:
	return consumer.actor.global_position.distance_squared_to(
		_factory_manager.grid.cell_to_world(destination),
	)


func is_actionable(consumer: JobConsumer) -> bool:
	return can_assign(consumer)


func can_take_over(
	consumer: JobConsumer,
	job: Job,
	current_consumer: JobConsumer,
) -> bool:
	var work_job := job as WorkJob
	if (
		consumer == null
		or work_job == null
		or current_consumer == null
		or not is_instance_valid(current_consumer)
		or not _consumer_can_work(consumer)
		or not _destination_is_available(current_consumer)
	):
		return false
	return true


func try_create_job(consumer: JobConsumer) -> Job:
	# JobQueue has already marked the request claimed at this point.
	if not _consumer_can_work(consumer) or not _is_needed():
		return null
	if not _reservation_manager.try_reserve_all(
		consumer,
		[destination],
	):
		return null

	return WorkJob.new(work_type, destination, machine)


func _consumer_can_work(consumer: JobConsumer) -> bool:
	return (
		consumer != null
		and consumer.capability != null
		and consumer.capability.can_perform(work_type)
	)


func _is_needed() -> bool:
	if machine == null or not is_instance_valid(machine):
		return false
	for need in machine.get_remaining_work_needs():
		if need.cell == destination and need.work_type == work_type:
			return true
	return false


func _destination_is_available(ignoring: Object = null) -> bool:
	if _factory_manager == null or _factory_manager.grid == null:
		return false
	return not _reservation_manager.is_reserved(destination, ignoring)
