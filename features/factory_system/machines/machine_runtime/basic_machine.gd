class_name BasicMachine
extends Machine

@export var hide_inputs_while_processing := true

var _processing_recipe: ProductionRecipe
var _processing_elapsed := 0.0
var _claimed_inputs: Array[FactoryItem] = []
var _claimed_input_positions: Dictionary[FactoryItem, Vector3] = {}
var _factory_manager: FactoryManager

var _occupied_work_cells: Dictionary[StringName, WorkerCapability] = {}


func _factory_tick(delta: float, factory_manager: FactoryManager) -> void:

	if factory_manager == null:
		return

	_factory_manager = factory_manager

	#start processing if currently has no task running
	if _processing_recipe == null:
		_try_start_processing(factory_manager)
		return


	_update_job_requests()

	var duration := maxf(_processing_recipe.duration_seconds, 0.0)
	if _processing_elapsed < duration:
		if not _check_workable(_processing_recipe):
			unregister_active()
			return

		register_active(faith_drain_rate)
		_processing_elapsed = minf(_processing_elapsed + delta, duration)
		if _processing_elapsed < duration:
			return

		_occupied_work_cells.clear()


	register_active(faith_drain_rate)

	if not _try_spawn_outputs(factory_manager):
		return

	var completed_recipe := _processing_recipe
	_consume_claimed_inputs(factory_manager)
	_clear_processing_state()
	if not _on_recipe_completed(completed_recipe, factory_manager):
		unregister_active()
		return
	
	# immediately try again, if not then it must be idle
	_try_start_processing(factory_manager)
	if _processing_recipe == null:
		unregister_active()



func is_processing_recipe() -> bool:
	return _processing_recipe != null


func has_all_required_inputs_in_place(
	recipe: ProductionRecipe,
	factory_manager: FactoryManager,
) -> bool:
	if recipe == null or factory_manager == null or definition == null:
		return false
	var assembly := get_parent() as MachineAssembly
	if assembly == null or assembly.block == null or assembly.block.block_data == null:
		return false
	var required_count := _get_required_input_count(recipe)
	return (
		required_count >= 0
		and _find_input_items(recipe, factory_manager).size() == required_count
	)

func get_remaining_work_needs() -> Array[Dictionary]:
	var needs: Array[Dictionary] = []
	if (
		_processing_recipe == null
		or get_processing_progress() >= 1.0
		or definition == null
	):
		return needs
	var assembly := get_parent() as MachineAssembly
	if assembly == null or assembly.block == null or assembly.block.block_data == null:
		return needs
	for requirement in _processing_recipe.work_requirements:
		if (
			requirement == null
			or _occupied_work_cells.has(requirement.port_id)
		):
			continue
		for cell in get_cells_for_port(
			MachineCellDefinition.Role.WORK,
			requirement.port_id,
		):
			needs.append({
				"port_id": requirement.port_id,
				"cell": cell,
				"work_type": requirement.work_type,
			})
	return needs

func get_processing_progress() -> float:
	if not is_processing_recipe():
		return 0.0
	var duration := _processing_recipe.duration_seconds
	if duration <= 0.0:
		return 1.0
	return clampf(_processing_elapsed / duration, 0.0, 1.0)


## Called after outputs have spawned, inputs have been consumed, and the
## processing state has been cleared. Return false to prevent another recipe
## from starting during the same factory tick.
func _on_recipe_completed(
	_completed_recipe: ProductionRecipe,
	_factory_manager: FactoryManager,
) -> bool:
	return true

func _exit_tree() -> void:
	_cancel_processing()


func _try_start_processing(factory_manager: FactoryManager) -> void:
	if definition == null or enabled_recipes.is_empty():
		return

	for recipe in enabled_recipes:
		if recipe == null:
			continue
		if _try_start_recipe(recipe, factory_manager):
			return


func _try_start_recipe(
	recipe: ProductionRecipe,
	factory_manager: FactoryManager,
) -> bool:
	var required_input_count := _get_required_input_count(recipe)
	var candidates := _find_input_items(recipe, factory_manager)
	if candidates.size() != required_input_count:
		return false

	var claimed_items: Array[FactoryItem] = []
	var original_positions: Dictionary[FactoryItem, Vector3] = {}
	for factory_item in candidates:
		var original_position: Vector3 = factory_item.get(&"global_position")
		if not factory_item.try_claim(self):
			_restore_claimed_inputs(
				claimed_items,
				original_positions,
				factory_manager,
			)
			return false

		claimed_items.append(factory_item)
		original_positions[factory_item] = original_position

	for factory_item in claimed_items:
		factory_item.set_in_process_hidden(hide_inputs_while_processing)

	_processing_recipe = recipe
	_processing_elapsed = 0.0
	_claimed_inputs = claimed_items
	_claimed_input_positions = original_positions
	if _check_workable(recipe):
		register_active(faith_drain_rate)
	else:
		unregister_active()
	return true


func _check_workable(recipe: ProductionRecipe) -> bool:
	if recipe == null:
		return false

	# No work requirements means the recipe remains fully automatic.
	for requirement in recipe.work_requirements:
		if (
			requirement == null
			or not _occupied_work_cells.has(requirement.port_id)
		):
			return false

		var capability := _occupied_work_cells.get(
			requirement.port_id,
		) as WorkerCapability
		if (
			capability == null
			or not capability.can_perform(requirement.work_type)
		):
			return false

	return true

func try_working_at_port(coord: Vector3i, capability: WorkerCapability) -> bool:
	if (
		capability == null
		or _processing_recipe == null
		or get_processing_progress() >= 1.0
	):
		return false

	var port_id := _get_work_port_id_at(coord)
	if (
		port_id.is_empty()
		or _occupied_work_cells.has(port_id)
		or _occupied_work_cells.values().has(capability)
	):
		return false

	for requirement in _processing_recipe.work_requirements:
		if (
			requirement == null
			or requirement.port_id != port_id
			or not capability.can_perform(requirement.work_type)
		):
			continue

		_occupied_work_cells[port_id] = capability
		return true

	return false


func try_unallocate_working_port(coord: Vector3i, capability: WorkerCapability) -> bool:
	var port_id := _get_work_port_id_at(coord)
	if (
		port_id.is_empty()
		or capability == null
		or _occupied_work_cells.get(port_id) != capability
	):
		return false

	_occupied_work_cells.erase(port_id)
	if (
		_processing_recipe != null
		and get_processing_progress() < 1.0
		and not _check_workable(_processing_recipe)
	):
		unregister_active()
	return true


func is_working_at_port(
	coord: Vector3i,
	capability: WorkerCapability,
) -> bool:
	if capability == null:
		return false
	var port_id := _get_work_port_id_at(coord)
	return (
		not port_id.is_empty()
		and _occupied_work_cells.get(port_id) == capability
	)


func _get_work_port_id_at(coord: Vector3i) -> StringName:
	if definition == null:
		return &""
	var assembly := get_parent() as MachineAssembly
	if assembly == null or assembly.block == null or assembly.block.block_data == null:
		return &""

	for cell_definition in definition.cells:
		if (
			cell_definition == null
			or cell_definition.role != MachineCellDefinition.Role.WORK
		):
			continue
		var cell_coord := assembly.block.block_data.world_cell_for_offset(
			cell_definition.local_cell_offset,
		)
		if cell_coord == coord:
			return cell_definition.port_id
	return &""

#try to search for the input item in the factory manager
func _find_input_items(
	recipe: ProductionRecipe,
	factory_manager: FactoryManager,
) -> Array[FactoryItem]:
	var result: Array[FactoryItem] = []
	var selected_items: Dictionary[FactoryItem, bool] = {}

	for requirement in recipe.inputs:
		if (
			requirement == null
			or requirement.item == null
			or requirement.amount <= 0
		):
			return []

		var amount_remaining := requirement.amount
		var input_cells := get_cells_for_port(
			MachineCellDefinition.Role.INPUT,
			requirement.port_id,
		)
		for cell in input_cells:
			for processable in factory_manager.get_processables_at(cell):
				var factory_item := processable as FactoryItem
				if (
					factory_item == null
					or selected_items.has(factory_item)
					or factory_item.stack.item_definition != requirement.item
					or not factory_item.is_available_for_processing()
				):
					continue

				result.append(factory_item)
				selected_items[factory_item] = true
				amount_remaining -= 1
				if amount_remaining == 0:
					break

			if amount_remaining == 0:
				break

		if amount_remaining != 0:
			return []

	return result


func _get_required_input_count(recipe: ProductionRecipe) -> int:
	var result := 0
	for requirement in recipe.inputs:
		if requirement == null or requirement.amount <= 0:
			return -1
		result += requirement.amount
	return result



func _try_spawn_outputs(factory_manager: FactoryManager) -> bool:
	if _processing_recipe == null:
		return false
	# An outputless recipe completes successfully without spawning anything.
	if _processing_recipe.outputs.is_empty():
		return true

	var spawned_outputs: Array[FactoryItem] = []
	var next_output_indices: Dictionary[StringName, int] = {}

	for output in _processing_recipe.outputs:
		if output == null or output.item == null or output.amount <= 0:
			_rollback_spawned_outputs(spawned_outputs, factory_manager)
			return false

		var output_cells := get_cells_for_port(
			MachineCellDefinition.Role.OUTPUT,
			output.port_id,
		)
		if output_cells.is_empty():
			_rollback_spawned_outputs(spawned_outputs, factory_manager)
			return false

		for _item_index in output.amount:
			var next_index: int = next_output_indices.get(output.port_id, 0)
			var output_cell := output_cells[next_index % output_cells.size()]
			var factory_item := FactoryItemFactory.spawn_factory_item_at_cell(
				output.item,
				output_cell,
				factory_manager,
			)
			if factory_item == null:
				_rollback_spawned_outputs(spawned_outputs, factory_manager)
				return false

			spawned_outputs.append(factory_item)
			next_output_indices[output.port_id] = next_index + 1

	return true


func _rollback_spawned_outputs(
	spawned_outputs: Array[FactoryItem],
	factory_manager: FactoryManager,
) -> void:
	for factory_item in spawned_outputs:
		if not is_instance_valid(factory_item):
			continue
		factory_manager.unregister_processable(factory_item)
		factory_item.queue_free()



func _consume_claimed_inputs(factory_manager: FactoryManager) -> void:
	for factory_item in _claimed_inputs:
		if not is_instance_valid(factory_item):
			continue
		factory_manager.unregister_processable(factory_item)
		factory_item.queue_free()


func _cancel_processing() -> void:
	if _processing_recipe == null:
		return

	_restore_claimed_inputs(
		_claimed_inputs,
		_claimed_input_positions,
		_factory_manager,
	)
	_clear_processing_state()
	unregister_active()


func _restore_claimed_inputs(
	claimed_items: Array[FactoryItem],
	original_positions: Dictionary[FactoryItem, Vector3],
	factory_manager: FactoryManager,
) -> void:
	for factory_item in claimed_items:
		if not is_instance_valid(factory_item):
			continue

		var original_position: Vector3 = original_positions.get(
			factory_item,
			factory_item.get(&"global_position"),
		)
		factory_item.set_in_process_hidden(false)
		factory_item.set(&"global_position", original_position)
		if (
			factory_manager != null
			and not factory_manager.is_processable_registered(factory_item)
		):
			factory_manager.register_processable(factory_item)
		factory_item.drop_at(original_position)


func _clear_processing_state() -> void:
	_occupied_work_cells.clear()
	_processing_recipe = null
	_processing_elapsed = 0.0
	_claimed_inputs.clear()
	_claimed_input_positions.clear()
