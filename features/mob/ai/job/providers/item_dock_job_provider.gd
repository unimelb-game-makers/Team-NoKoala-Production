class_name ItemDockJobProvider
extends MachineJobProvider

## Reconcile the provider-owned queue with the machine's current input needs.
## Existing requests are retained so their queue order remains stable.
func refresh() -> void:
	if _factory_manager == null or _machine == null:
		return

	var desired: Array[Dictionary] = []
	for item in _machine.allowed_items:
		if (
			item == null
		):
			continue

		var input_cells := _machine.get_cells_for_port(
			MachineCellDefinition.Role.INPUT,
			"input_1"
		)

		for input_cell in input_cells:
			if _reservation_manager.is_reserved(input_cell):
				continue
			if not _factory_manager.can_add_item_at_cell(
				input_cell,
				item,
			):
				continue
			if not _has_need(desired, item, input_cell):
				desired.append({"item": item, "cell": input_cell})

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
