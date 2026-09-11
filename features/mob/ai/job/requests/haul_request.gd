class_name HaulRequest
extends JobRequest

var item_definition: FactoryItemDefinition
var destination: Vector3i
var _factory_manager: FactoryManager


func _init(
	p_item_definition: FactoryItemDefinition,
	p_destination: Vector3i,
	p_factory_manager: FactoryManager,
) -> void:
	item_definition = p_item_definition
	destination = p_destination
	_factory_manager = p_factory_manager


func job_type() -> StringName:
	return HaulJob.JOB_TYPE


func score(consumer: JobConsumer) -> float:
	return consumer.actor.global_position.distance_squared_to(
		_factory_manager.grid.cell_to_world(destination),
	)


func is_actionable(consumer: JobConsumer) -> bool:
	return (
		super(consumer)
		and _destination_is_available()
		and _nearest_available_item(consumer.actor.global_position) != null
	)


func is_actionable_with_item(
	consumer: JobConsumer,
	item: FactoryItem,
) -> bool:
	return (
		can_assign(consumer)
		and _destination_is_available()
		and _is_available_matching_item(item)
	)


func can_take_over(
	consumer: JobConsumer,
	job: Job,
	current_consumer: JobConsumer,
) -> bool:
	var haul_job := job as HaulJob
	if (
		consumer == null
		or haul_job == null
		or current_consumer == null
		or not is_instance_valid(current_consumer)
		or not is_instance_valid(haul_job.item)
		or not _destination_is_available(current_consumer)
	):
		return false

	var item := haul_job.item
	if item.definition != item_definition:
		return false
	if ReservationManager.is_reserved(item, current_consumer):
		return false
	if item.is_dropped():
		return item.is_available_for_processing()
	return item.get_claimant() == current_consumer.actor


func try_create_job(consumer: JobConsumer) -> Job:
	var item := _nearest_available_item(consumer.actor.global_position)
	if item == null:
		return null
	return try_create_job_with_item(consumer, item)


func try_create_job_with_item(
	consumer: JobConsumer,
	item: FactoryItem,
) -> Job:
	if not _destination_is_available() or not _is_available_matching_item(item):
		return null

	if not ReservationManager.try_reserve_all(
		consumer,
		[item, destination],
	):
		return null

	return HaulJob.new(item, destination)


func _destination_is_available(ignoring: Object = null) -> bool:
	if _factory_manager == null or _factory_manager.grid == null:
		return false
	if not _factory_manager.accepts_item_at_cell(destination, item_definition):
		return false
	if not _factory_manager.get_processables_at(destination).is_empty():
		return false
	return not ReservationManager.is_reserved(destination, ignoring)


func _is_available_matching_item(item: FactoryItem) -> bool:
	if item == null or not is_instance_valid(item):
		return false
	if item.definition != item_definition:
		return false
	if not item.is_dropped() or not item.is_available_for_processing():
		return false
	if ReservationManager.is_reserved(item):
		return false
	var item_cell := _factory_manager.grid.world_to_cell(
		item.get_drop_world_position(),
	)
	return not _factory_manager.accepts_item_at_cell(item_cell, item.definition)


func _nearest_available_item(origin: Vector3) -> FactoryItem:
	var best_item: FactoryItem = null
	var best_distance := INF

	for processable in _factory_manager.get_processables():
		var item := processable as FactoryItem
		if item == null or not is_instance_valid(item):
			continue
		if not _is_available_matching_item(item):
			continue

		var distance := origin.distance_squared_to(item.global_position)
		if distance < best_distance:
			best_distance = distance
			best_item = item

	return best_item
