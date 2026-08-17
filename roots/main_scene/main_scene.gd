extends Node3D

@onready var camera: Camera3D = $Camera3D
@onready var grid_map: GridMap = $GridMap
@export var selected_tile: int = 0

var item_list: PackedInt32Array
var grid_data: GridData = GridData.new()

func _ready() -> void:
	item_list = grid_map.mesh_library.get_item_list()
	selected_tile = item_list[0]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_toggle_block()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("next_item"):
		_next_item()

func _next_item():
	var index = item_list.find(selected_tile)
	if index == item_list.size() - 1:
		selected_tile = item_list[0]
	else:
		selected_tile = item_list[index + 1]

func _toggle_block():
	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)
	var ray_end := ray_origin + ray_dir * 1000.0
	
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result := grid_map.get_world_3d().direct_space_state.intersect_ray(query)
	
	if result:
		var hit_pos: Vector3 = result.position
		var cell = grid_map.local_to_map(hit_pos - (result.normal * (grid_map.cell_size / 2.0)))
		cell.y = 0
		if grid_map.get_cell_item(cell) == GridMap.INVALID_CELL_ITEM:
			# If no block exists, place the selected block
			grid_map.set_cell_item(cell, selected_tile)
		else:
			# Otherwise, remove the existing block
			grid_map.set_cell_item(cell, GridMap.INVALID_CELL_ITEM)
