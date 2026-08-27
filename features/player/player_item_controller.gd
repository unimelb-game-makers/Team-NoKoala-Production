extends Node3D
class_name PlayerItemController

var held_factory_item: FactoryItem = null
@export var camera: Camera3D
@export var grid: Grid

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_RIGHT:
		return

	if held_factory_item != null:
		_try_drop_held_item()
	else:
		_try_pick_up_item_at_mouse()

func _process(_delta: float) -> void:
	if held_factory_item != null:
		held_factory_item.global_position = global_position

func _try_pick_up_item_at_mouse() -> void:
	var factory_item := _factory_item_at_mouse()
	if factory_item == null:
		return
	if global_position.distance_to(factory_item.global_position) > Player.PICKUP_DISTANCE:
		return
	if not factory_item.try_claim(get_parent()):
		return

	held_factory_item = factory_item
	get_viewport().set_input_as_handled()

func _try_drop_held_item() -> void:
	if grid == null:
		return

	var drop_cell := cell_at_mouse_position()
	var drop_position := grid.map_to_local(drop_cell)
	drop_position.y = 0.167

	if global_position.distance_to(drop_position) > Player.PICKUP_DISTANCE:
		return

	held_factory_item.drop_at(drop_position)
	held_factory_item.global_position = drop_position
	held_factory_item = null
	get_viewport().set_input_as_handled()

func _factory_item_at_mouse() -> FactoryItem:
	if camera == null:
		return null

	var mouse_position := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_position)
	var ray_end := ray_origin + camera.project_ray_normal(mouse_position) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var result := get_world_3d().direct_space_state.intersect_ray(query)
	var node := result.get("collider") as Node
	while node != null:
		if node is FactoryItem:
			return node as FactoryItem
		node = node.get_parent()

	return null


func cell_at_mouse_position() -> Vector3i:
	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)
	var ray_end := ray_origin + ray_dir * 1000.0
	
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result := grid.get_world_3d().direct_space_state.intersect_ray(query)
	
	if result:
		var hit_pos: Vector3 = result.position
		var cell = grid.local_to_map(hit_pos - (result.normal * (grid.cell_size / 2.0)))
		cell.y = 0
		return cell
	else:
		return Vector3i()
