class_name HaulJobProvider
extends JobProvider

var _machine: Machine
var _factory_manager: FactoryManager


func _ready() -> void:
	_machine = get_parent() as Machine
	_factory_manager = get_tree().get_first_node_in_group("factory_manager")

	if _factory_manager == null or _machine == null:
		return

	_factory_manager.machine_registered.connect(_on_machine_registered)
	_factory_manager.machine_unregistered.connect(_on_machine_unregistered)

	if _factory_manager.is_machine_registered(_machine):
		activate()


func _on_machine_registered(machine: Machine) -> void:
	if machine == _machine:
		activate()


func _on_machine_unregistered(machine: Machine) -> void:
	if machine == _machine:
		deactivate()


func job_type() -> StringName:
	return HaulJob.JOB_TYPE


func find_job(consumer: JobConsumer) -> Job:
	if _factory_manager == null or _machine == null:
		return null

	var demands := _machine.get_demands()
	if demands.is_empty():
		return null

	var origin: Vector3 = consumer.actor.global_position

	var item := _nearest_wanted_item(origin, demands)
	if item == null:
		return null

	var matching_demand := _nearest_demand_for_item(demands, item.definition, origin)
	if matching_demand == null:
		return null

	if not ReservationManager.try_reserve_all(consumer, [item, matching_demand.cell]):
		return null

	_machine.consume_demand(matching_demand)

	return HaulJob.new(item, matching_demand.cell)


func score(consumer: JobConsumer) -> float:
	if _factory_manager == null or _machine == null:
		return INF

	var demand := _machine.get_demands()
	if demand.is_empty():
		return INF

	var origin: Vector3 = consumer.actor.global_position
	var best := INF
	for entry in demand:
		best = min(
			best,
			origin.distance_squared_to(_factory_manager.grid.cell_to_world(entry.cell)),
		)
	return best


func _nearest_wanted_item(
	origin: Vector3,
	demands: Array[MachineDemand],
) -> FactoryItem:
	var best_item: FactoryItem = null
	var best_distance := INF

	for processable in _factory_manager.get_processables():
		var item := processable as FactoryItem
		if item == null or not is_instance_valid(item):
			continue

		if not item.is_dropped() or not item.available_for_processing:
			continue

		if not _demands_wants_item(demands, item.definition):
			continue

		if ReservationManager.is_reserved(item):
			continue

		# Already delivered onto some machine's input cell, awaiting consumption.
		var item_cell := _factory_manager.grid.world_to_cell(
			item.get_drop_world_position()
		)
		if _factory_manager.accepts_item_at_cell(item_cell, item.definition):
			continue

		var distance := origin.distance_squared_to(item.global_position)
		if distance < best_distance:
			best_distance = distance
			best_item = item

	return best_item


func _demands_wants_item(
	demands: Array[MachineDemand],
	item: FactoryItemDefinition,
) -> bool:
	for entry in demands:
		if entry.item == item:
			return true
	return false


func _nearest_demand_for_item(
	demands: Array[MachineDemand],
	item: FactoryItemDefinition,
	origin: Vector3,
) -> MachineDemand:
	var best: MachineDemand = null
	var best_distance := INF
	for entry in demands:
		if entry.item != item:
			continue
		var distance := origin.distance_squared_to(
			_factory_manager.grid.cell_to_world(entry.cell)
		)
		if distance < best_distance:
			best_distance = distance
			best = entry
	return best
