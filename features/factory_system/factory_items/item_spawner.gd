## Places factory items into the level and registers them with the factory.
class_name ItemSpawner
extends Node

@export var items_root: Node
@export var factory_manager: FactoryManager

const FACTORY_ITEM_SCENE = preload(
	"res://features/factory_system/factory_items/factory_item.tscn"
)
const DEFAULT_SPAWN_HEIGHT := 0.167

var _warned_missing_root := false


func configure(p_items_root: Node, p_factory_manager: FactoryManager) -> void:
	items_root = p_items_root
	factory_manager = p_factory_manager


func spawn_factory_item(
	definition: FactoryItemDefinition,
	global_position: Vector3,
	stack: ItemStack = null,
) -> FactoryItem:
	if factory_manager == null:
		return null

	var factory_item := create_factory_item(definition, stack)
	if factory_item == null:
		return null

	factory_item.factory_manager = factory_manager

	if items_root != null:
		items_root.add_child(factory_item)
	else:
		if not _warned_missing_root:
			printerr("ItemSpawner has no items_root; adding items to the scene root")
			_warned_missing_root = true
		get_tree().root.add_child(factory_item)

	factory_item.global_position = global_position
	if not factory_manager.register_processable(factory_item):
		factory_item.queue_free()
		return null

	if factory_item.try_drop(global_position):
		factory_item.drop_at(global_position)
	return factory_item


func spawn_factory_item_at_cell(
	definition: FactoryItemDefinition,
	cell: Vector3i,
) -> FactoryItem:
	if factory_manager == null or factory_manager.grid == null:
		return null

	var world_position := factory_manager.grid.cell_to_world(cell)
	world_position.y = DEFAULT_SPAWN_HEIGHT
	return spawn_factory_item(definition, world_position)


static func create_factory_item(
	definition: FactoryItemDefinition,
	stack: ItemStack = null,
) -> FactoryItem:
	if definition == null:
		return null

	var factory_item := FACTORY_ITEM_SCENE.instantiate() as FactoryItem
	if factory_item == null:
		return null

	if stack == null:
		factory_item.stack = ItemStack.new(definition)
	else:
		factory_item.stack = stack
	return factory_item
