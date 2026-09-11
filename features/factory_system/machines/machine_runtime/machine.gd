class_name Machine
extends Node

@export var definition: MachineDefinition

## Recipes that the player has enabled
@export var active_recipes: Array[ProductionRecipe] = []
@export var job_provider: MachineJobProvider

var center_position: Vector3i = Vector3i.ZERO

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


func _update_job_requests() -> void:
	if job_provider != null:
		job_provider.refresh()
