class_name FactoryItemSpawnController
extends Node

@export var spring_arm: CameraController
@export var grid: Grid
@export var factory_manager: FactoryManager
@export var spawn_height := 0.167
@export var item_definition : FactoryItemDefinition

func configure(p_spring_arm: CameraController, p_grid: Grid, p_factory_manager: FactoryManager) -> void:
	spring_arm = p_spring_arm
	grid = p_grid
	factory_manager = p_factory_manager


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("spawn_factory_item"):
		spawn_factory_item_at_mouse(item_definition.item_key)

func spawn_factory_item_at_mouse(
	item_definition: FactoryItemDefinition.FactoryItemID,
) -> FactoryItem:
	if spring_arm == null or grid == null or factory_manager == null:
		return null

	var cell := cell_at_mouse_position()
	var world_position := grid.cell_to_world(cell)
	world_position.y = spawn_height
	return spawn_factory_item(item_definition, world_position)

func cell_at_mouse_position() -> Vector3i:
	if spring_arm == null or grid == null:
		return Vector3i.ZERO

	var mouse_position := get_viewport().get_mouse_position()
	var ray_origin := spring_arm.camera.project_ray_origin(mouse_position)
	var ray_end := (
		ray_origin
		+ spring_arm.camera.project_ray_normal(mouse_position) * 1000.0
	)
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result := grid.get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return Vector3i.ZERO

	var hit_position: Vector3 = result.position
	var hit_normal: Vector3 = result.normal
	var cell := grid.world_to_cell(
		hit_position - hit_normal * (grid.cell_size / 2.0)
	)
	cell.y = 0
	return cell

func spawn_factory_item(
	item_definition: FactoryItemDefinition.FactoryItemID,
	world_position: Vector3,
) -> FactoryItem:
	var definition_path: String = FactoryItemDefinition.factory_item_definitions.get(
		item_definition,
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
