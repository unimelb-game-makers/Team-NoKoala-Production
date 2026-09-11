class_name Machine
extends Node

@export var definition: MachineDefinition

## Recipes that the player has enabled
@export var active_recipes: Array[ProductionRecipe] = []

var center_position: Vector3i = Vector3i.ZERO

var _demand_queue: Array[MachineDemand] = []

func is_recipe_active(recipe: ProductionRecipe) -> bool:
	return recipe != null and active_recipes.has(recipe)


func activate_recipe(recipe: ProductionRecipe) -> bool:
	if definition == null or not definition.has_recipe(recipe):
		return false
	if not active_recipes.has(recipe):
		active_recipes.append(recipe)
	return true


func deactivate_recipe(recipe: ProductionRecipe) -> void:
	active_recipes.erase(recipe)


func set_active_recipes(recipes: Array[ProductionRecipe]) -> void:
	var result: Array[ProductionRecipe] = []
	for recipe in recipes:
		if definition != null and definition.has_recipe(recipe) and not result.has(recipe):
			result.append(recipe)
	active_recipes = result


func get_input_cells() -> Array[Vector3i]:
	return _get_cells_for_role(MachineCellDefinition.Role.INPUT)

func get_output_cells() -> Array[Vector3i]:
	return _get_cells_for_role(MachineCellDefinition.Role.OUTPUT)

func get_cells_for_port(
	role: MachineCellDefinition.Role,
	port_id: StringName,
) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	var assembly := get_parent() as MachineAssembly
	for cell_definition in definition.cells:
		if (
			cell_definition.role == role
			and cell_definition.port_id == port_id
		):
			result.append(
				assembly.block.block_data.world_cell_for_offset(
					cell_definition.local_cell_offset,
				)
			)
	return result

func _get_cells_for_role(
	role: MachineCellDefinition.Role,
) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	var assembly := get_parent() as MachineAssembly
	for cell_definition in definition.cells:
		if cell_definition.role == role:
			result.append(
				assembly.block.block_data.world_cell_for_offset(
					cell_definition.local_cell_offset,
				)
			)
	return result


func factory_tick(_delta: float, _factory_manager: FactoryManager) -> void:
	pass


func accepts_item_at_cell(item: FactoryItemDefinition, cell: Vector3i) -> bool:
	if item == null or definition == null:
		return false

	var port_id := _get_input_port_id_for_cell(cell)
	if port_id.is_empty():
		return false

	for recipe in active_recipes:
		if recipe == null:
			continue
		for requirement in recipe.inputs:
			if (
				requirement != null
				and requirement.port_id == port_id
				and requirement.item == item
			):
				return true

	return false


func _get_input_port_id_for_cell(cell: Vector3i) -> StringName:
	var assembly := get_parent() as MachineAssembly
	if assembly == null:
		return &""

	for cell_definition in definition.cells:
		if cell_definition.role != MachineCellDefinition.Role.INPUT:
			continue
		if (
			assembly.block.block_data.world_cell_for_offset(
				cell_definition.local_cell_offset,
			) == cell
		):
			return cell_definition.port_id

	return &""


func get_demands() -> Array[MachineDemand]:
	return _demand_queue.duplicate()


## Returns false if it was already gone (e.g. already consumed by another job provider).
func consume_demand(demand: MachineDemand) -> bool:
	var index := _demand_queue.find(demand)
	if index == -1:
		return false
	_demand_queue.remove_at(index)
	return true


func _update_demand(factory_manager: FactoryManager) -> void:
	var demand_queue: Array[MachineDemand] = []

	if definition == null:
		_demand_queue = demand_queue
		return

	for recipe in active_recipes:
		if recipe == null:
			continue

		for requirement in recipe.inputs:
			if requirement == null or requirement.item == null:
				continue

			for input_cell in get_cells_for_port(
				MachineCellDefinition.Role.INPUT,
				requirement.port_id,
			):
				if not factory_manager.get_processables_at(input_cell).is_empty():
					continue
				# A job provider already committed to filling this cell;
				# don't offer it again until that reservation is released.
				if ReservationManager.is_reserved(input_cell):
					continue
				if _demand_queue_has(demand_queue, requirement.item, input_cell):
					continue
				demand_queue.append(MachineDemand.new(requirement.item, input_cell))

	_demand_queue = demand_queue


func _demand_queue_has(
	demand_queue: Array[MachineDemand],
	item: FactoryItemDefinition,
	cell: Vector3i,
) -> bool:
	for entry in demand_queue:
		if entry.item == item and entry.cell == cell:
			return true
	return false
