## Optional capability on a MachineAssembly. Stages machine-defined returns;
## the assembly removes itself and each runtime releases its own held items.
class_name DismantleComponent
extends Node

signal changed

@export var enabled := true:
	set(value):
		enabled = value
		changed.emit()

var assembly: MachineAssembly
var _factory_manager: FactoryManager
var _dismantling := false
var _runtimes: Array[Machine] = []


func configure(p_assembly: MachineAssembly, factory_manager: FactoryManager) -> void:
	for runtime in _runtimes:
		if is_instance_valid(runtime):
			runtime.dismantle_returns_changed.disconnect(_on_returns_changed)
	_runtimes.clear()
	assembly = p_assembly
	_factory_manager = factory_manager
	for runtime in [assembly.machine, assembly.blueprint]:
		if runtime != null and not _runtimes.has(runtime):
			runtime.dismantle_returns_changed.connect(_on_returns_changed)
			_runtimes.append(runtime)


func _on_returns_changed() -> void:
	changed.emit()


func can_dismantle() -> bool:
	if (
		not enabled
		or _dismantling
		or not is_instance_valid(assembly)
	):
		return false
	if get_refund().is_empty():
		return true
	return (
		is_instance_valid(_factory_manager)
		and is_instance_valid(_factory_manager.item_spawner)
		and _factory_manager.item_spawner.factory_manager == _factory_manager
	)


func get_refund() -> Array[ItemStack]:
	if not is_instance_valid(assembly):
		return []
	var runtime := assembly.get_active_machine()
	return runtime.get_dismantle_returns() if is_instance_valid(runtime) else []


func try_dismantle() -> bool:
	if not can_dismantle():
		return false
	_dismantling = true
	var position := _factory_manager.grid.cell_to_world(assembly.block.block_data.root_cell)
	position.y += ItemSpawner.DEFAULT_SPAWN_HEIGHT
	var prepared: Array[FactoryItem] = []
	for refund in get_refund():
		var remaining := refund.quantity
		while remaining > 0:
			var stack := ItemStack.new(refund.item_definition)
			stack.stack_size = maxi(1, refund.item_definition.max_stack)
			stack.quantity = mini(remaining, stack.stack_size)
			# Prepare unregistered items first: a spawn failure must leave the
			# machine and its held items intact, without merging a partial refund.
			var item := _factory_manager.item_spawner.spawn_factory_item(
				stack.item_definition, position, stack, true,
			)
			if item == null:
				_discard_prepared(prepared)
				return false
			item.set_available_for_processing(false)
			prepared.append(item)
			remaining -= stack.quantity

	if not assembly.remove_from_world():
		_discard_prepared(prepared)
		return false
	for item in prepared:
		_factory_manager.register_processable(item)
		item.drop_at(position)
	return true


func _discard_prepared(items: Array[FactoryItem]) -> void:
	for item in items:
		item.free()
	_dismantling = false
	changed.emit()
