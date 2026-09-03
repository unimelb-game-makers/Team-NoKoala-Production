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

	var origin: Vector3 = consumer.actor.global_position

	var cell = _nearest_free_input_cell(origin)
	if cell == null:
		return null

	var item := _find_nearest_haulable_item(origin)
	if item == null:
		return null

	if not ReservationManager.try_reserve(consumer, item):
		return null

	return HaulJob.new(item, cell)


func score(consumer: JobConsumer) -> float:
	if _factory_manager == null or _machine == null:
		return INF

	var origin: Vector3 = consumer.actor.global_position
	var best := INF
	for input_cell in _machine.get_input_cells():
		if not _factory_manager.get_processables_at(input_cell).is_empty():
			continue
		var distance := origin.distance_squared_to(
			_factory_manager.grid.cell_to_world(input_cell)
		)
		best = min(best, distance)
	return best


## The empty input cell of this machine nearest to `origin`, or null if every
## input cell already holds an item.
func _nearest_free_input_cell(origin: Vector3) -> Variant:
	var best: Variant = null
	var best_distance := INF
	for input_cell in _machine.get_input_cells():
		if not _factory_manager.get_processables_at(input_cell).is_empty():
			continue
		var distance := origin.distance_squared_to(
			_factory_manager.grid.cell_to_world(input_cell)
		)
		if distance < best_distance:
			best_distance = distance
			best = input_cell
	return best


func _find_nearest_haulable_item(origin: Vector3) -> FactoryItem:
	var best_item: FactoryItem = null
	var best_distance := INF

	for processable in _factory_manager.get_processables():
		var item := processable as FactoryItem
		if item == null or not is_instance_valid(item):
			continue

		if not item.is_dropped() or not item.available_for_processing:
			continue

		if ReservationManager.is_reserved(item):
			continue

		if _item_on_input_cell(item):
			continue

		var distance := origin.distance_squared_to(item.global_position)
		if distance < best_distance:
			best_distance = distance
			best_item = item

	return best_item


func _item_on_input_cell(item: FactoryItem) -> bool:
	var cell := _factory_manager.grid.world_to_cell(item.get_drop_world_position())
	for machine in _factory_manager.get_machines():
		if cell in machine.get_input_cells():
			return true
	return false
