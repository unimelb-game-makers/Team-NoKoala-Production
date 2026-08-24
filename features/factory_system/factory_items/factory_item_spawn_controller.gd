class_name FactoryItemSpawnController
extends Node

@export var grid_controller: GridInteractionController
@export var factory_manager: FactoryManager
@export var spawn_height := 0.167

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("spawn_factory_item"):
		spawn_factory_item_at_mouse(FactoryItemDefinition.FactoryItemID.IRON_ORE)

func spawn_factory_item_at_mouse(
	item_id: FactoryItemDefinition.FactoryItemID,
) -> FactoryItem:
	if grid_controller == null or factory_manager == null:
		return null

	var cell := grid_controller.cell_at_mouse_position()
	var world_position := grid_controller.position_at_cell(cell)
	world_position.y = spawn_height
	return spawn_factory_item(item_id, world_position)

func spawn_factory_item(
	item_id: FactoryItemDefinition.FactoryItemID,
	world_position: Vector3,
) -> FactoryItem:
	var definition_path: String = FactoryItemDefinition.factory_item_definitions.get(
		item_id,
		"",
	)
	if definition_path.is_empty() or factory_manager == null:
		return null

	var definition := load(definition_path) as FactoryItemDefinition
	if definition == null:
		return null

	return FactoryItemFactory.spawn_factory_item(
		definition,
		world_position,
		factory_manager,
	)
