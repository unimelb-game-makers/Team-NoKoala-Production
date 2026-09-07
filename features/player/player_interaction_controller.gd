class_name PlayerInteractionController
extends Node

@export var camera: Camera3D

var player: Node3D
var grid: Grid
var _inventory_owner: InventoryOwner

func _ready() -> void:
	player = get_parent()
	grid = get_tree().get_first_node_in_group("grid")
	_inventory_owner = NodeUtils.get_child_by_type(player, InventoryOwner)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_RIGHT:
		return

	if _inventory_owner.inventory.hand_slot != null:
		_try_drop_held_item()
	else:
		_try_pick_up_item_at_mouse()


func _try_pick_up_item_at_mouse() -> void:
	var factory_item := _factory_item_at_mouse()
	print(factory_item)
	if _inventory_owner.try_pick_up_item(factory_item):
		get_viewport().set_input_as_handled()


func _try_drop_held_item() -> void:	
	if _inventory_owner.try_drop_held_item():
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

	var result := player.get_world_3d().direct_space_state.intersect_ray(query)
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
