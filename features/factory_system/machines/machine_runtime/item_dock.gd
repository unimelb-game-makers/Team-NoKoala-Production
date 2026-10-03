class_name ItemDock
extends Machine

@export var hide_inputs_while_processing := true

const DEFAULT_SPAWN_HEIGHT: float = 0.167

var _factory_manager: FactoryManager

var allowed_items: Array[FactoryItemDefinition] = []

func _factory_tick(_delta: float, factory_manager: FactoryManager) -> void:

	if factory_manager == null:
		return

	_factory_manager = factory_manager
	
	var candidates := _find_input_items(factory_manager)

	for factory_item in candidates:
		var world_position := factory_manager.grid.cell_to_world(get_output_cells()[0])
		factory_item.try_drop(world_position)
		factory_item.drop_at(Vector3(world_position.x, DEFAULT_SPAWN_HEIGHT, world_position.z))

#try to search for the input item in the factory manager
func _find_input_items(
	factory_manager: FactoryManager,
) -> Array[FactoryItem]:
	var result: Array[FactoryItem] = []

	var input_cells := get_cells_for_port(
		MachineCellDefinition.Role.INPUT,
		"input_1"
	)
	for cell in input_cells:
		for processable in factory_manager.get_processables_at(cell):
			
			var factory_item := processable as FactoryItem
			if (
				factory_item == null
				or factory_item.stack.item_definition not in allowed_items
				or not factory_item.is_available_for_processing()
			):
				continue

			result.append(factory_item)

	return result

func has_allowed_item(item: FactoryItemDefinition) -> bool:
	if item in allowed_items: return true
	return false
