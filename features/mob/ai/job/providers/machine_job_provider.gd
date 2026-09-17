class_name MachineJobProvider
extends JobProvider

var _machine: Machine
var _factory_manager: FactoryManager
var _reservation_manager: ReservationManager


func configure(
	factory_manager: FactoryManager,
	job_board: JobBoard,
	reservation_manager: ReservationManager,
) -> void:
	_job_board = job_board
	_factory_manager = factory_manager
	_reservation_manager = reservation_manager
	_machine = get_parent() as Machine
	_bind_factory_manager()


func _bind_factory_manager() -> void:
	if not _factory_manager.machine_registered.is_connected(_on_machine_registered):
		_factory_manager.machine_registered.connect(_on_machine_registered)
	if not _factory_manager.machine_unregistered.is_connected(_on_machine_unregistered):
		_factory_manager.machine_unregistered.connect(_on_machine_unregistered)
	if _factory_manager.is_machine_registered(_machine):
		activate()


func _on_machine_registered(machine: Machine) -> void:
	if machine == _machine:
		activate()


func _on_machine_unregistered(machine: Machine) -> void:
	if machine == _machine:
		deactivate()


## Reconcile the provider-owned queue with the machine's current input needs.
## Existing requests are retained so their queue order remains stable.
func refresh() -> void:
	if _factory_manager == null or _machine == null:
		return

	var desired: Array[Dictionary] = []
	for recipe in _machine.enabled_recipes:
		if recipe == null:
			continue
		for requirement in recipe.inputs:
			if requirement == null or requirement.item == null:
				continue
			for input_cell in _machine.get_cells_for_port(
				MachineCellDefinition.Role.INPUT,
				requirement.port_id,
			):
				if not _factory_manager.get_processables_at(input_cell).is_empty():
					continue
				if _reservation_manager.is_reserved(input_cell):
					continue
				if not _has_need(desired, requirement.item, input_cell):
					desired.append({"item": requirement.item, "cell": input_cell})

	for request in get_requests():
		var haul_request := request as HaulRequest
		if haul_request == null:
			continue
		if not _has_need(desired, haul_request.item_definition, haul_request.destination):
			remove(haul_request)

	for need in desired:
		if not _has_request(need.item, need.cell):
			enqueue(
				HaulRequest.new(
					need.item,
					need.cell,
					_factory_manager,
					_reservation_manager,
				)
			)


func _has_request(item: FactoryItemDefinition, cell: Vector3i) -> bool:
	for request in get_requests():
		var haul_request := request as HaulRequest
		if (
			haul_request != null
			and haul_request.item_definition == item
			and haul_request.destination == cell
		):
			return true
	return false


func _has_need(
	needs: Array[Dictionary],
	item: FactoryItemDefinition,
	cell: Vector3i,
) -> bool:
	for need in needs:
		if need.item == item and need.cell == cell:
			return true
	return false
