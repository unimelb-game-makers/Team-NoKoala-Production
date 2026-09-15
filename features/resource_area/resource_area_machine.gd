@tool
class_name ResourceAreaMachine
extends Machine

@export var _processing_recipe: ProductionRecipe
var _processing_elapsed := 0.0
var _factory_manager: FactoryManager
@export var sprite: Sprite3D
@export var block: Block
@export var _resource_area_definition : ResourceAreaDefinition
@export var _spawn_if_output_present_toggle: bool

func _ready() -> void:
	sprite.texture = _resource_area_definition.texture
	_processing_recipe = _resource_area_definition.spawner_recipe

func factory_tick(delta: float, factory_manager: FactoryManager) -> void:
	if factory_manager == null:
		return
	
	_factory_manager = factory_manager

	#start processing if currently has no task running
	if _processing_recipe == null:
		_try_start_processing()
		return

	_processing_elapsed += delta
	if _processing_elapsed < _processing_recipe.duration_seconds:
		return

	if not _try_spawn_outputs(factory_manager):
		return
	
	_clear_processing_state()


func _exit_tree() -> void:
	_cancel_processing()


func _try_start_processing() -> void:
	if _resource_area_definition == null or _resource_area_definition.spawner_recipe == null:
		return
	if not _spawn_if_output_present_toggle and _detect_items_in_output(): return

	var recipe := _resource_area_definition.spawner_recipe
	if recipe == null:
		return

	_processing_recipe = recipe
	_processing_elapsed = 0.0

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

func _cancel_processing() -> void:
	if _processing_recipe == null:
		return
	
	_clear_processing_state()

func _clear_processing_state() -> void:
	_processing_recipe = null
	_processing_elapsed = 0.0
	_factory_manager = null

func _detect_items_in_output() -> bool:
	if len(_factory_manager.get_processables_at(block.block_data.world_cell_for_offset(Vector3i(0, 0, 1)))) > 0:
		return true
	else: return false
