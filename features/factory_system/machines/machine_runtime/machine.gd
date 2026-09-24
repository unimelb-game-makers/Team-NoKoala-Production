class_name Machine
extends Node

enum ProgressPhase {
	NONE,
	MATERIALS,
	WORK,
}

signal factory_ticked(machine: Machine, delta: float)
signal enabled_recipes_changed
signal blueprint_constructed
signal work_port_enabled_changed(port: WorkPort, enabled: bool)
signal work_port_allocation_changed(port: WorkPort, worker: WorkerCapability)

@export var definition: MachineDefinition

## Recipes that the player has enabled
@export var enabled_recipes: Array[ProductionRecipe] = []
@export var job_provider: MachineJobProvider

@export var faith_drain_rate: float = 0.0
@export var debug_active_indicator: Node3D

@export var disabled: bool = true

var center_position: Vector3i = Vector3i.ZERO
var is_active: bool = false
var is_shut_down: bool = false
var faith_manager: FaithManager
var work_ports: Array[WorkPort] = []
var _work_ports_valid := true
var mobs_root: Node


func configure(p_faith_manager: FaithManager, p_mobs_root: Node) -> void:
	faith_manager = p_faith_manager
	mobs_root = p_mobs_root


func is_recipe_enabled(recipe: ProductionRecipe) -> bool:
	return recipe != null and enabled_recipes.has(recipe)


func enable_recipe(recipe: ProductionRecipe) -> bool:
	if definition == null or not definition.has_recipe(recipe):
		return false
	if not enabled_recipes.has(recipe):
		enabled_recipes.append(recipe)
		enabled_recipes_changed.emit()
	return true


func disable_recipe(recipe: ProductionRecipe) -> void:
	if enabled_recipes.has(recipe):
		enabled_recipes.erase(recipe)
		enabled_recipes_changed.emit()


func set_enabled_recipes(recipes: Array[ProductionRecipe]) -> void:
	var result: Array[ProductionRecipe] = []
	for recipe in recipes:
		if definition != null and definition.has_recipe(recipe) and not result.has(recipe):
			result.append(recipe)
	enabled_recipes = result
	enabled_recipes_changed.emit()


func _exit_tree() -> void:
	unregister_active()


func get_input_cells() -> Array[Vector3i]:
	return _get_cells_for_role(MachineCellDefinition.Role.INPUT)


func get_output_cells() -> Array[Vector3i]:
	return _get_cells_for_role(MachineCellDefinition.Role.OUTPUT)


func get_work_cells() -> Array[Vector3i]:
	return _get_cells_for_role(MachineCellDefinition.Role.WORK)


func get_occupied_cells() -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	var assembly := get_parent() as MachineAssembly
	if (
		definition == null
		or assembly == null
		or assembly.block == null
		or assembly.block.block_data == null
	):
		return result

	for cell_definition in definition.cells:
		if cell_definition == null:
			continue
		result.append(
			assembly.block.block_data.world_cell_for_offset(
				cell_definition.local_cell_offset,
			)
		)
	return result


func is_processing_recipe() -> bool:
	return false


func get_processing_progress() -> float:
	return 0.0


func get_progress_phase() -> ProgressPhase:
	return ProgressPhase.NONE


func get_progress_text() -> String:
	if get_progress_phase() != ProgressPhase.WORK:
		return ""
	return "Work %d%%" % roundi(get_processing_progress() * 100.0)


func get_pending_input_requirements() -> Array[RecipeItemAmount]:
	var requirements: Array[RecipeItemAmount] = []
	if disabled or is_shut_down or is_processing_recipe():
		return requirements

	for recipe in enabled_recipes:
		if recipe == null:
			continue
		for requirement in recipe.inputs:
			if requirement != null:
				requirements.append(requirement)
	return requirements


func locks_item_pickup_at_cell(
	_item: FactoryItemDefinition,
	_cell: Vector3i,
) -> bool:
	return false


func allows_stacked_input_at_cell(
	_item: FactoryItemDefinition,
	_cell: Vector3i,
) -> bool:
	return false


func get_delivered_input_amount(
	item: FactoryItemDefinition,
	cells: Array[Vector3i],
	factory_manager: FactoryManager,
) -> int:
	var amount := 0
	for cell in cells:
		for processable in factory_manager.get_processables_at(cell):
			var factory_item := processable as FactoryItem
			if (
				factory_item != null
				and factory_item.stack != null
				and factory_item.stack.item_definition == item
				and factory_item.is_available_for_processing()
			):
				amount += 1
	return amount


func configure_work_ports(recipe: ProductionRecipe) -> bool:
	clear_work_ports()
	if recipe == null:
		_work_ports_valid = false
		return false

	var configured_port_ids: Dictionary[StringName, bool] = {}
	for requirement in recipe.work_requirements:
		if (
			requirement == null
			or requirement.port_id.is_empty()
			or configured_port_ids.has(requirement.port_id)
		):
			_work_ports_valid = false
			continue

		var cells := get_cells_for_port(
			MachineCellDefinition.Role.WORK,
			requirement.port_id,
		)
		if cells.is_empty():
			_work_ports_valid = false
			continue

		configured_port_ids[requirement.port_id] = true
		var port := WorkPort.new(
			requirement.port_id,
			requirement.work_type,
			cells,
		)
		port.enabled_changed.connect(_on_work_port_enabled_changed)
		port.allocation_changed.connect(_on_work_port_allocation_changed)
		work_ports.append(port)
	return _work_ports_valid


func clear_work_ports() -> void:
	work_ports.clear()
	_work_ports_valid = true


func are_work_ports_ready() -> bool:
	if not _work_ports_valid:
		return false
	for port in work_ports:
		if not port.is_ready():
			return false
	return true


func get_remaining_work_needs() -> Array[Dictionary]:
	var needs: Array[Dictionary] = []
	if disabled or is_shut_down or not _work_ports_valid:
		return needs

	for port in work_ports:
		if not port.enabled or port.worker != null:
			continue
		for cell in port.cells:
			needs.append({
				"port_id": port.port_id,
				"cell": cell,
				"work_type": port.work_type,
			})
	return needs


func try_working_at_port(
	cell: Vector3i,
	capability: WorkerCapability,
) -> bool:
	if disabled or is_shut_down or not _work_ports_valid or capability == null:
		return false
	if _find_port_for_worker(capability) != null:
		return false

	var port := _find_work_port_at(cell)
	return port != null and port.try_allocate(capability)


func try_unallocate_working_port(
	cell: Vector3i,
	capability: WorkerCapability,
) -> bool:
	var port := _find_work_port_at(cell)
	if port == null or not port.try_release(capability):
		return false

	if not are_work_ports_ready():
		unregister_active()
	return true


func is_working_at_port(
	cell: Vector3i,
	capability: WorkerCapability,
) -> bool:
	var port := _find_work_port_at(cell)
	return port != null and port.is_allocated_to(capability)


func get_work_port(port_id: StringName) -> WorkPort:
	for port in work_ports:
		if port.port_id == port_id:
			return port
	return null


func set_work_port_enabled(port_id: StringName, enabled: bool) -> bool:
	var port := get_work_port(port_id)
	if port == null:
		return false
	port.enabled = enabled
	return true


func _on_work_port_enabled_changed(port: WorkPort, enabled: bool) -> void:
	if not enabled:
		unregister_active()
	_update_job_requests()
	work_port_enabled_changed.emit(port, enabled)


func _on_work_port_allocation_changed(
	port: WorkPort,
	worker: WorkerCapability,
) -> void:
	work_port_allocation_changed.emit(port, worker)


func _find_work_port_at(cell: Vector3i) -> WorkPort:
	for port in work_ports:
		if port.contains_cell(cell):
			return port
	return null


func _find_port_for_worker(capability: WorkerCapability) -> WorkPort:
	for port in work_ports:
		if port.is_allocated_to(capability):
			return port
	return null


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
	if disabled or is_shut_down:
		return
	_factory_tick(_delta, _factory_manager)
	factory_ticked.emit(self, _delta)

func _factory_tick(_delta: float, _factory_manager: FactoryManager) -> void:
	pass


func accepts_item_at_cell(item: FactoryItemDefinition, cell: Vector3i) -> bool:
	if disabled or is_shut_down or item == null or definition == null:
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

func enable() -> void:
	disabled = false
	_update_job_requests()
	_on_enabled_changed(true)

func disable() -> void:
	disabled = true
	unregister_active()
	_update_job_requests()
	_on_enabled_changed(false)

## Override to start or stop effects (animations, particles, sounds) so a
## disabled machine, such as one still under construction, has none.
func _on_enabled_changed(_enabled: bool) -> void:
	pass
