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


func try_create_job(consumer: JobConsumer) -> Job:
	var item := _nearest_available_item(consumer.actor.global_position)
	if item == null:
		return null

	if not ReservationManager.try_reserve_all(
		consumer,
		[item, destination],
	):
		return null

	return HaulJob.new(item, destination)


func _nearest_available_item(origin: Vector3) -> FactoryItem:
	var best_item: FactoryItem = null
	var best_distance := INF

	for processable in _factory_manager.get_processables():
		var item := processable as FactoryItem
		if item == null or not is_instance_valid(item):
			continue
		if item.definition != item_definition:
			continue
		if not item.is_dropped() or not item.available_for_processing:
			continue
		if ReservationManager.is_reserved(item):
			continue

		# Items already delivered to a machine input are awaiting consumption.
		var item_cell := _factory_manager.grid.world_to_cell(
			item.get_drop_world_position(),
		)
		if _factory_manager.accepts_item_at_cell(item_cell, item.definition):
			continue

		var distance := origin.distance_squared_to(item.global_position)
		if distance < best_distance:
			best_distance = distance
			best_item = item

	return best_item
