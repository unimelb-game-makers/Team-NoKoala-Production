class_name FactoryItemFactory

const FACTORY_ITEM_SCENE = preload(
	"res://features/factory_system/factory_items/factory_item.tscn"
)
const DEFAULT_SPAWN_HEIGHT := 0.167


static func create_factory_item(
	definition: FactoryItemDefinition,
) -> FactoryItem:
	if definition == null:
		return null

	var factory_item := FACTORY_ITEM_SCENE.instantiate() as FactoryItem
	if factory_item == null:
		return null

	factory_item.definition = definition
	return factory_item


static func spawn_factory_item(
	definition: FactoryItemDefinition,
	world_position: Vector3,
	factory_manager: FactoryManager,
) -> FactoryItem:
	if (
		factory_manager == null
		or factory_manager.processables_container == null
	):
		return null

	var factory_item := create_factory_item(definition)
	if factory_item == null:
		return null

	factory_manager.processables_container.add_child(factory_item)
	factory_item.set(&"global_position", world_position)
	if not factory_manager.register_processable(factory_item):
		factory_item.queue_free()
		return null

	factory_item.drop_at(world_position)
	return factory_item


static func spawn_factory_item_at_cell(
	definition: FactoryItemDefinition,
	cell: Vector3i,
	factory_manager: FactoryManager,
) -> FactoryItem:
	if factory_manager == null or factory_manager.grid == null:
		return null

	var world_position := factory_manager.grid.cell_to_world(cell)
	world_position.y = DEFAULT_SPAWN_HEIGHT
	return spawn_factory_item(definition, world_position, factory_manager)
