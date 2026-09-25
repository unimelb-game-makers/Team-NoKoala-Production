class_name MachineJobProvider
extends JobProvider

var _machine: Machine
var _factory_manager: FactoryManager
var _reservation_manager: ReservationManager


func configure(
	factory_manager: FactoryManager,
	job_board: JobBoard,
	reservation_manager: ReservationManager,
	p_machine: Machine,
) -> void:
	_job_board = job_board
	_factory_manager = factory_manager
	_reservation_manager = reservation_manager
	_machine = p_machine
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
	for requirement in _machine.get_pending_input_requirements():
		if (
			requirement == null
			or requirement.item == null
			or requirement.amount <= 0
		):
			continue

		var input_cells := _machine.get_cells_for_port(
			MachineCellDefinition.Role.INPUT,
			requirement.port_id,
		)
		var amount_remaining := requirement.amount - _machine.get_delivered_input_amount(
			requirement.item,
			input_cells,
			_factory_manager,
		)
		for input_cell in input_cells:
			if amount_remaining <= 0:
				break
			if _reservation_manager.is_reserved(input_cell):
				amount_remaining -= 1
				continue
			if not _factory_manager.can_add_item_at_cell(
				input_cell,
				requirement.item,
			):
				continue
			if not _has_need(desired, requirement.item, input_cell):
				desired.append({"item": requirement.item, "cell": input_cell})
				amount_remaining -= 1

	for request in get_requests():
		var haul_request := request as HaulRequest
		if haul_request == null:
			continue
		if not _has_need(desired, haul_request.item_definition, haul_request.destination):
			remove(haul_request)

	for need in desired:
		var haul_request := HaulRequest.new(
							need.item,
							need.cell,
							_factory_manager,
							_reservation_manager,
						)
		if not _has_request(haul_request):
			enqueue(haul_request)
	var works := _machine.get_remaining_work_needs()
	for request in get_requests():
		var work_request := request as WorkRequest
		if work_request == null:
			continue
		var still_needed := false
		for work in works:
			if (
				work_request.machine == _machine
				and work_request.destination == work.cell
				and work_request.work_type == work.work_type
			):
				still_needed = true
				break
		if not still_needed:
			remove(work_request)
	for work in works:
		if _reservation_manager.is_reserved(work.cell):
			continue
		var work_request := WorkRequest.new(
			work.work_type,
			work.cell,
			_factory_manager,
			_reservation_manager,
			_machine,
		)
		if not _has_request(work_request):
			enqueue(work_request)


func _has_request(p_request : JobRequest) -> bool:
	for request in get_requests():
		if p_request.equals(request):
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
