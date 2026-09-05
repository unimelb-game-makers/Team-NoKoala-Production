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

	var demand := _input_demand()
	if demand.is_empty():
		return null

	var origin: Vector3 = consumer.actor.global_position

	var item := _nearest_wanted_item(origin, demand)
	if item == null:
		return null

	var cell = _nearest_cell(demand[item.definition], origin)
	if cell == null:
		return null

	if not ReservationManager.try_reserve(consumer, item):
		return null

	return HaulJob.new(item, cell)


func score(consumer: JobConsumer) -> float:
	if _factory_manager == null or _machine == null:
		return INF

	var demand := _input_demand()
	if demand.is_empty():
		return INF

	var origin: Vector3 = consumer.actor.global_position
	var best := INF
	for cells in demand.values():
		var cell = _nearest_cell(cells, origin)
		if cell != null:
			best = min(
				best,
				origin.distance_squared_to(_factory_manager.grid.cell_to_world(cell)),
			)
	return best


## Returns a map from `FactoryItemDefinition` to input cells
func _input_demand() -> Dictionary:
	var demand: Dictionary = {}

	var definition := _machine.definition
	if definition == null:
		return demand

	for recipe in definition.recipes:
		if recipe == null:
			continue

		for requirement in recipe.inputs:
			if requirement == null or requirement.item == null:
				continue

			var free_cells: Array[Vector3i] = []
			for input_cell in _machine.get_cells_for_port(
				MachineCellDefinition.Role.INPUT,
				requirement.port_id,
			):
				if _factory_manager.get_processables_at(input_cell).is_empty():
					free_cells.append(input_cell)

			if free_cells.is_empty():
				continue

			if demand.has(requirement.item):
				for input_cell in free_cells:
					if not demand[requirement.item].has(input_cell):
						demand[requirement.item].append(input_cell)
			else:
				demand[requirement.item] = free_cells

	return demand


func _nearest_wanted_item(origin: Vector3, demand: Dictionary) -> FactoryItem:
	var best_item: FactoryItem = null
	var best_distance := INF

	for processable in _factory_manager.get_processables():
		var item := processable as FactoryItem
		if item == null or not is_instance_valid(item):
			continue

		if not item.is_dropped() or not item.available_for_processing:
			continue

		if not demand.has(item.definition):
			continue

		if ReservationManager.is_reserved(item):
			continue

		# Already delivered onto some machine's input cell, awaiting consumption.
		var item_cell := _factory_manager.grid.world_to_cell(
			item.get_drop_world_position()
		)
		if _is_input_cell(item_cell):
			continue

		var distance := origin.distance_squared_to(item.global_position)
		if distance < best_distance:
			best_distance = distance
			best_item = item

	return best_item


func _is_input_cell(cell: Vector3i) -> bool:
	var blocks := _factory_manager.grid.get_blocks_at(cell)
	for block in blocks:
		var assembly := block.get_parent() as MachineAssembly
		if assembly == null or assembly.machine == null:
			continue
		if assembly.machine.get_input_cells().has(cell):
			return true
	return false


func _nearest_cell(cells: Array, origin: Vector3) -> Variant:
	var best: Variant = null
	var best_distance := INF
	for cell in cells:
		var distance := origin.distance_squared_to(
			_factory_manager.grid.cell_to_world(cell)
		)
		if distance < best_distance:
			best_distance = distance
			best = cell
	return best
