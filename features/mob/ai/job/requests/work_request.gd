class_name WorkRequest
extends JobRequest

## One request per machine work port. The port's cells are only standing spots,
## so the actual cell is chosen when a consumer claims the request.
var work_type: WorkType.Value
var port_id: StringName
var machine: Machine
var _factory_manager: FactoryManager
var _reservation_manager: ReservationManager


func _init(
	p_work_type: WorkType.Value,
	p_port_id: StringName,
	p_factory_manager: FactoryManager,
	p_reservation_manager: ReservationManager,
	p_machine: Machine,
) -> void:
	work_type = p_work_type
	port_id = p_port_id
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
		and work.port_id == port_id
		and work.machine == machine
		and work._factory_manager == _factory_manager
	)


func can_assign(consumer: JobConsumer) -> bool:
	return (
		super(consumer)
		and _consumer_can_work(consumer)
		and not _available_cells().is_empty()
	)


func score(consumer: JobConsumer) -> float:
	var cell: Variant = _nearest_available_cell(consumer)
	if cell == null:
		return INF
	return consumer.actor.global_position.distance_squared_to(
		_factory_manager.grid.cell_to_world(cell),
	)


func is_actionable(consumer: JobConsumer) -> bool:
	return can_assign(consumer)


func can_take_over(
	consumer: JobConsumer,
	job: Job,
	current_consumer: JobConsumer,
) -> bool:
	var work_job := job as WorkJob
	return (
		consumer != null
		and work_job != null
		and current_consumer != null
		and is_instance_valid(current_consumer)
		and _consumer_can_work(consumer)
	)


func try_create_job(consumer: JobConsumer) -> Job:
	# JobQueue has already marked the request claimed at this point.
	if not _consumer_can_work(consumer):
		return null
	var cell: Variant = _nearest_available_cell(consumer)
	if cell == null:
		return null
	if not _reservation_manager.try_reserve_all(consumer, [cell]):
		return null

	return WorkJob.new(work_type, cell, machine)


func _consumer_can_work(consumer: JobConsumer) -> bool:
	return (
		consumer != null
		and consumer.capability != null
		and consumer.capability.can_perform(work_type)
	)


## Cells of this port the machine still needs worked and nobody has reserved.
func _available_cells() -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	if (
		machine == null
		or not is_instance_valid(machine)
		or _factory_manager == null
		or _factory_manager.grid == null
	):
		return result
	for need in machine.get_remaining_work_needs():
		if (
			need.port_id == port_id
			and need.work_type == work_type
			and not _reservation_manager.is_reserved(need.cell)
		):
			result.append(need.cell)
	return result


func _nearest_available_cell(consumer: JobConsumer) -> Variant:
	var best: Variant = null
	var best_distance := INF
	for cell in _available_cells():
		var distance := consumer.actor.global_position.distance_squared_to(
			_factory_manager.grid.cell_to_world(cell),
		)
		if distance < best_distance:
			best = cell
			best_distance = distance
	return best
