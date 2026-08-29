extends Node
class_name ConveyorManager

@export var camera: Camera3D
@export var grid: Grid

var _placement_hint_block: ConveyorBelt
var previous_rotation: BlockData.Rotation # store rotation for cleaner placement

const DIRECTIONS = {
	BlockData.Rotation.DEG0:   Vector3i(0, 0, -1),
	BlockData.Rotation.DEG90:  Vector3i(-1, 0, 0),
	BlockData.Rotation.DEG180: Vector3i(0, 0, 1),
	BlockData.Rotation.DEG270: Vector3i(1, 0, 0),
}

func _ready() -> void:
	_placement_hint_block = ConveyorFactory.create_conveyor_belt()
	grid.add_block_visual(_placement_hint_block)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("rotate"):
		_rotate_block()
	if _placement_hint_block != null:
		if not camera: return 
		var cell = cell_at_mouse_position()
		grid.move_block_visual(_placement_hint_block, cell)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			previous_rotation = _placement_hint_block.block_data.block_rotation
			_place_block()
	
func _place_block():
	if _placement_hint_block != null:
		var cell = cell_at_mouse_position()
		_placement_hint_block.is_placed = true
		if grid.move_block(_placement_hint_block, cell):
			_placement_hint_block = ConveyorFactory.create_conveyor_belt()
			_placement_hint_block.set_rotation_data(previous_rotation)
			grid.add_block_visual(_placement_hint_block)

func _rotate_block():
	if _placement_hint_block != null:
		_placement_hint_block.switch_rotation()

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

func position_at_cell(cell: Vector3i) -> Vector3:
	return grid.map_to_local(cell)
