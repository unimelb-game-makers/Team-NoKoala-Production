class_name BlueprintMachine
extends Machine

const CONSTRUCTION_PORT := &"construction"

var _construction_elapsed := 0.0
var _construction_started := false
var _claimed_materials: Dictionary[FactoryItem, int] = {}
var _claimed_material_positions: Dictionary[FactoryItem, Vector3] = {}
var _factory_manager: FactoryManager


func configure_construction(machine_definition: MachineDefinition) -> void:
	definition = machine_definition
	enabled_recipes.clear()
	_clear_construction_state()


func _factory_tick(delta: float, factory_manager: FactoryManager) -> void:
	if factory_manager == null or definition == null:
		return

	_factory_manager = factory_manager
	_update_job_requests()

	if not _construction_started:
		if not _try_begin_construction(factory_manager):
			unregister_active()
			return
		_update_job_requests()

	if not are_work_ports_ready():
		unregister_active()
		return

	register_active(faith_drain_rate)
	if is_shut_down:
		return

	_construction_elapsed = minf(
		_construction_elapsed + delta,
		definition.construction_time_seconds,
	)
	if _construction_elapsed < definition.construction_time_seconds:
		return

	_consume_claimed_materials(factory_manager)
	clear_work_ports()
	_construction_started = false
	construction_completed()


func construction_completed() -> void:
	blueprint_constructed.emit()


func is_processing_recipe() -> bool:
	return _construction_started


func get_progress_phase() -> ProgressPhase:
	if disabled or definition == null:
		return ProgressPhase.NONE
	if _construction_started:
		return ProgressPhase.WORK
	return ProgressPhase.MATERIALS


func get_progress_text() -> String:
	if _construction_started:
		return "Build %d%%" % roundi(get_processing_progress() * 100.0)
	return "Materials %d/%d" % [
		_get_delivered_material_amount(),
		_get_total_material_amount(),
	]


func get_processing_progress() -> float:
	if not _construction_started:
		return get_material_progress()
	if definition == null or definition.construction_time_seconds <= 0.0:
		return 1.0
	return clampf(
		_construction_elapsed / definition.construction_time_seconds,
		0.0,
		1.0,
	)


func get_material_progress() -> float:
	var total_required := _get_total_material_amount()
	if total_required <= 0:
		return 0.0
	return clampf(
		float(_get_delivered_material_amount()) / float(total_required),
		0.0,
		1.0,
	)


## Amount of [param item] supplied towards construction, capped at the
## required amount. Claimed materials count as fully supplied.
func get_supplied_material_amount(item: FactoryItemDefinition) -> int:
	var required := _get_required_amount_for(item)
	if _construction_started:
		return required
	return mini(_get_delivered_amount_for(item), required)


func get_input_cells() -> Array[Vector3i]:
	return get_occupied_cells()


func get_output_cells() -> Array[Vector3i]:
	return []


func get_work_cells() -> Array[Vector3i]:
	return get_occupied_cells()


func get_cells_for_port(
	role: MachineCellDefinition.Role,
	_port_id: StringName,
) -> Array[Vector3i]:
	if (
		role == MachineCellDefinition.Role.INPUT
		or role == MachineCellDefinition.Role.WORK
	):
		return get_occupied_cells()
	return []


func get_pending_input_requirements() -> Array[RecipeItemAmount]:
	if disabled or is_shut_down or _construction_started or definition == null:
		return []
	return definition.construction_materials.duplicate()


func accepts_item_at_cell(
	item: FactoryItemDefinition,
	cell: Vector3i,
) -> bool:
	if (
		disabled
		or _construction_started
		or definition == null
		or item == null
		or not get_occupied_cells().has(cell)
	):
		return false
	return _get_delivered_amount_for(item) < _get_required_amount_for(item)


func locks_item_pickup_at_cell(
	item: FactoryItemDefinition,
	cell: Vector3i,
) -> bool:
	return (
		not disabled
		and not _construction_started
		and item != null
		and get_occupied_cells().has(cell)
		and _get_required_amount_for(item) > 0
	)


func allows_stacked_input_at_cell(
	item: FactoryItemDefinition,
	cell: Vector3i,
) -> bool:
	return locks_item_pickup_at_cell(item, cell)


func get_delivered_input_amount(
	item: FactoryItemDefinition,
	cells: Array[Vector3i],
	factory_manager: FactoryManager,
) -> int:
	var amount := 0
	for cell in cells:
		for processable in factory_manager.get_processables_at(cell):
			var material := processable as FactoryItem
			if (
				material != null
				and material.stack != null
				and material.stack.item_definition == item
				and material.is_available_for_processing()
			):
				amount += material.stack.quantity
	return amount


func _try_begin_construction(factory_manager: FactoryManager) -> bool:
	var allocations = _find_material_allocations(factory_manager)
	if allocations == null:
		return false

	var claimed: Array[FactoryItem] = []
	for material: FactoryItem in allocations:
		var original_position: Vector3 = material.global_position
		if not material.try_claim(self):
			_restore_materials(claimed, factory_manager)
			return false
		claimed.append(material)
		_claimed_materials[material] = allocations[material]
		_claimed_material_positions[material] = original_position

	for material in claimed:
		material.set_in_process_hidden(true)

	_construction_started = true
	_construction_elapsed = 0.0
	_configure_construction_work_port()
	return true


func _configure_construction_work_port() -> void:
	clear_work_ports()
	var requirement := RecipeWorkRequirement.new()
	requirement.port_id = CONSTRUCTION_PORT
	requirement.work_type = WorkType.Value.CONSTRUCTION
	var recipe := ProductionRecipe.new()
	recipe.work_requirements = [requirement]
	configure_work_ports(recipe)


func _find_material_allocations(factory_manager: FactoryManager):
	var allocations: Dictionary[FactoryItem, int] = {}
	if definition == null:
		return null

	for requirement in definition.construction_materials:
		if (
			requirement == null
			or requirement.item == null
			or requirement.amount <= 0
		):
			return null

		var amount_remaining := requirement.amount
		for cell in get_occupied_cells():
			for processable in factory_manager.get_processables_at(cell):
				var material := processable as FactoryItem
				if (
					material == null
					or allocations.has(material)
					or material.stack == null
					or material.stack.item_definition != requirement.item
					or not material.is_available_for_processing()
				):
					continue

				var amount := mini(material.stack.quantity, amount_remaining)
				allocations[material] = amount
				amount_remaining -= amount
				if amount_remaining == 0:
					break
			if amount_remaining == 0:
				break

		if amount_remaining != 0:
			return null

	return allocations


func _get_total_material_amount() -> int:
	if definition == null:
		return 0
	var total := 0
	for requirement in definition.construction_materials:
		if requirement != null and requirement.amount > 0:
			total += requirement.amount
	return total


func _get_delivered_material_amount() -> int:
	if definition == null or _factory_manager == null:
		return 0
	var delivered := 0
	for requirement in definition.construction_materials:
		if requirement == null or requirement.item == null:
			continue
		delivered += mini(
			_get_delivered_amount_for(requirement.item),
			requirement.amount,
		)
	return delivered


func _get_required_amount_for(item: FactoryItemDefinition) -> int:
	if definition == null:
		return 0
	var amount := 0
	for requirement in definition.construction_materials:
		if requirement != null and requirement.item == item:
			amount += maxi(requirement.amount, 0)
	return amount


func _get_delivered_amount_for(item: FactoryItemDefinition) -> int:
	if _factory_manager == null:
		return 0
	return get_delivered_input_amount(
		item,
		get_occupied_cells(),
		_factory_manager,
	)


func _consume_claimed_materials(factory_manager: FactoryManager) -> void:
	for material: FactoryItem in _claimed_materials:
		if not is_instance_valid(material):
			continue
		var amount: int = _claimed_materials[material]
		material.stack.quantity -= amount
		if material.stack.is_empty():
			factory_manager.unregister_processable(material)
			material.queue_free()
			continue

		material.set_in_process_hidden(false)
		material.global_position = _claimed_material_positions.get(
			material,
			material.global_position,
		)
		material.drop_at(material.global_position)

	_claimed_materials.clear()
	_claimed_material_positions.clear()


func _restore_materials(
	materials: Array[FactoryItem],
	factory_manager: FactoryManager,
) -> void:
	for material in materials:
		if not is_instance_valid(material):
			continue
		material.set_in_process_hidden(false)
		material.global_position = _claimed_material_positions.get(
			material,
			material.global_position,
		)
		if not factory_manager.is_processable_registered(material):
			factory_manager.register_processable(material)
		material.drop_at(material.global_position)
	_claimed_materials.clear()
	_claimed_material_positions.clear()


func _clear_construction_state() -> void:
	clear_work_ports()
	_construction_started = false
	_construction_elapsed = 0.0
	_claimed_materials.clear()
	_claimed_material_positions.clear()


func _exit_tree() -> void:
	if not _claimed_materials.is_empty() and _factory_manager != null:
		var materials: Array[FactoryItem] = []
		for material: FactoryItem in _claimed_materials:
			materials.append(material)
		_restore_materials(materials, _factory_manager)
	unregister_active()
