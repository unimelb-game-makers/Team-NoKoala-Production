class_name Machine
extends Node

signal factory_ticked(machine: Machine, delta: float)

@export var definition: MachineDefinition

## Recipes that the player has enabled
@export var enabled_recipes: Array[ProductionRecipe] = []
@export var job_provider: MachineJobProvider

@export var faith_drain_rate: float = 0.0
@export var debug_active_indicator: Node3D

var center_position: Vector3i = Vector3i.ZERO
var is_active: bool = false
var is_shut_down: bool = false
var faith_manager: FaithManager


func configure(p_faith_manager: FaithManager) -> void:
	faith_manager = p_faith_manager


func is_recipe_enabled(recipe: ProductionRecipe) -> bool:
	return recipe != null and enabled_recipes.has(recipe)


func enable_recipe(recipe: ProductionRecipe) -> bool:
	if definition == null or not definition.has_recipe(recipe):
		return false
	if not enabled_recipes.has(recipe):
		enabled_recipes.append(recipe)
	return true


func disable_recipe(recipe: ProductionRecipe) -> void:
	enabled_recipes.erase(recipe)


func set_enabled_recipes(recipes: Array[ProductionRecipe]) -> void:
	var result: Array[ProductionRecipe] = []
	for recipe in recipes:
		if definition != null and definition.has_recipe(recipe) and not result.has(recipe):
			result.append(recipe)
	enabled_recipes = result


func _exit_tree() -> void:
	unregister_active()


func get_input_cells() -> Array[Vector3i]:
	return _get_cells_for_role(MachineCellDefinition.Role.INPUT)


func get_output_cells() -> Array[Vector3i]:
	return _get_cells_for_role(MachineCellDefinition.Role.OUTPUT)


func get_work_cells() -> Array[Vector3i]:
	return _get_cells_for_role(MachineCellDefinition.Role.WORK)


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


func register_active(drain_rate: float = 0.0) -> void:
	if is_active:
		return
	if drain_rate > 0.0 and not faith_manager.try_drain():
		# Out of faith: shut down rather than run for free. FactoryManager
		# reactivates shut-down machines once faith is restored.
		force_shutdown()
		return
	faith_manager.register_drain(self, drain_rate)
	is_active = true
	_set_debug_indicator(true)


func unregister_active() -> void:
	if is_active:
		if faith_manager != null:
			faith_manager.unregister_drain(self)
		is_active = false
		_set_debug_indicator(false)


func _set_debug_indicator(active: bool) -> void:
	if debug_active_indicator:
		debug_active_indicator.visible = active


func factory_tick(_delta: float, _factory_manager: FactoryManager) -> void:
	if is_shut_down:
		return
	_factory_tick(_delta, _factory_manager)
	factory_ticked.emit(self, _delta)

func _factory_tick(_delta: float, _factory_manager: FactoryManager) -> void:
	pass


func accepts_item_at_cell(item: FactoryItemDefinition, cell: Vector3i) -> bool:
	if item == null or definition == null:
		return false

	var port_id := _get_input_port_id_for_cell(cell)
	if port_id.is_empty():
		return false

	for recipe in enabled_recipes:
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
		
func force_shutdown() -> void:
	is_shut_down = true
	unregister_active()

func reactivate() -> void:
	is_shut_down = false
