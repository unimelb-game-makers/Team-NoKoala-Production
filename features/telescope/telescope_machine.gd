class_name TelescopeMachine
extends BasicMachine

@export var recipes : Array[ProductionRecipe] = []

var repair_stage : int = 0
var waiting_for_discovery : bool = false
var _supplied: Dictionary[FactoryItemDefinition, int] = {}
var _held: Array[FactoryItem] = []

signal repair_completed
signal input_supplied(item: FactoryItemDefinition, total: int)

func _on_recipe_completed(
	_completed_recipe: ProductionRecipe,
	factory_manager: FactoryManager,
) -> bool:
	
	repair_stage += 1
	waiting_for_discovery = true
	_supplied.clear()
	repair_completed.emit()

	return true

func resume() -> void:
	waiting_for_discovery = false
	
func _try_start_processing(factory_manager: FactoryManager) -> void:
	if waiting_for_discovery or definition == null or repair_stage >= recipes.size():
		return
	var recipe := recipes[repair_stage]
	
	# try to do the whole thing first
	if _is_fully_supplied(recipe):
		_processing_recipe = recipe
		_processing_elapsed = 0.0
		_claimed_inputs = _held.duplicate()
		_held.clear()
		# TO DO: check if spirits will operate this?
		if _check_workable(recipe):
			register_active(faith_drain_rate)
		else:
			unregister_active()
		return
	
	# then check for partial inputs
	_try_partial_input(recipe, factory_manager)
	
	for req in recipe.inputs:
		if _supplied.get(req.item, 0) < req.amount:
			_try_start_recipe(recipe, factory_manager)
			return

func _is_fully_supplied(recipe: ProductionRecipe) -> bool:
	for req in recipe.inputs:
		if _supplied.get(req.item, 0) < req.amount:
			return false
	return true
	
func _try_partial_input(recipe: ProductionRecipe, factory_manager: FactoryManager) -> void:
	for required in recipe.inputs:
		var needed: int = required.amount - _supplied.get(required.item, 0)
		if needed <= 0:
			continue
	
		for cell in get_cells_for_port(MachineCellDefinition.Role.INPUT, required.port_id):
				for processable in factory_manager.get_processables_at(cell).duplicate():
					var item := processable as FactoryItem
					if (item == null
						or item.stack.item_definition != required.item
						or not item.is_available_for_processing()):
						continue
					var claimed := item

					if item.stack.quantity > needed:
						# split off only what is needed
						var split_stack = item.stack.split(needed)
						claimed = FactoryItemFactory.spawn_factory_item(
							item.stack.item_definition,
							item.transform.origin,
							factory_manager,
							split_stack,
							true)
						if not claimed.try_claim(self):
							item.stack.quantity += split_stack.quantity
							claimed.queue_free()
							continue
					elif not item.try_claim(self):
						continue

					claimed.set_in_process_hidden(hide_inputs_while_processing)
					_held.append(claimed)
					
					var taken: int = claimed.stack.quantity
					_supplied[required.item] = _supplied.get(required.item, 0) + taken
					input_supplied.emit(required.item, _supplied[required.item])
					needed -= taken
					if needed <= 0:
						break
				if needed <= 0:
					break
