class_name BasicMachine
extends Machine

var _processing_recipe: ProductionRecipe
var _processing_elapsed := 0.0
var _claimed_inputs: Array[FactoryItem] = []
var _claimed_input_positions: Dictionary[FactoryItem, Vector3] = {}
var _factory_manager: FactoryManager


func factory_tick(delta: float, factory_manager: FactoryManager) -> void:
	if factory_manager == null:
		return

	_factory_manager = factory_manager

	#start processing if currently has no task running
	if _processing_recipe == null:
		_try_start_processing(factory_manager)
		return

	_processing_elapsed += delta
	if _processing_elapsed < _processing_recipe.duration_seconds:
		return

	if not _try_spawn_outputs(factory_manager):
		return

	_consume_claimed_inputs(factory_manager)
	_clear_processing_state()
	
	# immediately try again, if not then it must be idle
	_try_start_processing(factory_manager)
	if _processing_recipe == null:
		unregister_active()


func _exit_tree() -> void:
	_cancel_processing()


func _try_start_processing(factory_manager: FactoryManager) -> void:
	if definition == null or definition.recipes.is_empty():
		return

	var recipe := definition.recipes[0]
	if recipe == null:
		return

	var required_input_count := _get_required_input_count(recipe)
	var candidates := _find_input_items(recipe, factory_manager)
	if candidates.size() != required_input_count:
		return

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
			return

		claimed_items.append(factory_item)
		original_positions[factory_item] = original_position

	for factory_item in claimed_items:
		factory_item.set_in_process_hidden(true)

	_processing_recipe = recipe
	_processing_elapsed = 0.0
	_claimed_inputs = claimed_items
	_claimed_input_positions = original_positions
	register_active(faith_drain_rate)


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
					or factory_item.definition != requirement.item
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
	_processing_recipe = null
	_processing_elapsed = 0.0
	_claimed_inputs.clear()
	_claimed_input_positions.clear()
	_factory_manager = null
