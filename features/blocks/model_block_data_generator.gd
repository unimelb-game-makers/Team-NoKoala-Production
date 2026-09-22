## tool used to quickly convert buildings to grid data

@tool
class_name ModelBlockDataGenerator
extends Node

const CELL_BOUNDARY_EPSILON := 0.0001

@export var block: Block
@export var models_root: Node3D
@export var cell_size := Vector3.ONE
@export var project_models_to_ground := true

@export_tool_button("Generate Block Data", "Callable")
var generate_button := generate_block_data


func generate_block_data() -> void:
	if not Engine.is_editor_hint():
		return

	var target_block := _get_block()

	var model_nodes: Array[VisualInstance3D] = []
	_collect_model_nodes(models_root, model_nodes)

	var generated_cells: Dictionary[Vector3i, bool] = {}
	var transform_root := (
		target_block.transform_root
		if target_block.transform_root != null
		else target_block
	)
	for model in model_nodes:
		_add_model_cells(model, transform_root, generated_cells)

	if generated_cells.is_empty():
		push_warning("Models Root contains no model geometry")
		return

	var footprint: Array[Vector3i] = []
	footprint.assign(generated_cells.keys())
	footprint.sort_custom(_cell_less_than)

	if target_block.block_data == null:
		target_block.block_data = BlockData.new()
		target_block.block_data.resource_local_to_scene = true

	var retained_overlap_cells: Array[Vector3i] = []
	for cell in target_block.block_data.overlap_cells:
		if generated_cells.has(cell):
			retained_overlap_cells.append(cell)

	target_block.block_data.footprint = footprint
	target_block.block_data.overlap_cells = retained_overlap_cells
	target_block.block_data.emit_changed()


func _get_block() -> Block:
	if block != null:
		return block

	var ancestor := get_parent()
	while ancestor != null:
		if ancestor is Block:
			return ancestor as Block
		ancestor = ancestor.get_parent()
	return null


func _collect_model_nodes(
	root: Node,
	result: Array[VisualInstance3D],
) -> void:
	if root is VisualInstance3D:
		result.append(root as VisualInstance3D)
	for child in root.get_children():
		_collect_model_nodes(child, result)


func _add_model_cells(
	model: VisualInstance3D,
	transform_root: Node3D,
	result: Dictionary[Vector3i, bool],
) -> void:
	var model_bounds := model.get_aabb()
	if model_bounds.size.is_zero_approx():
		return

	var model_to_block := (
		transform_root.global_transform.affine_inverse()
		* model.global_transform
	)
	var local_min := Vector3(INF, INF, INF)
	var local_max := Vector3(-INF, -INF, -INF)
	for x_side in 2:
		for y_side in 2:
			for z_side in 2:
				var corner := model_bounds.position + Vector3(
					model_bounds.size.x * x_side,
					model_bounds.size.y * y_side,
					model_bounds.size.z * z_side,
				)
				var local_corner := model_to_block * corner
				local_min = local_min.min(local_corner)
				local_max = local_max.max(local_corner)

	var min_cell := _bounds_min_cell(local_min)
	var max_cell := _bounds_max_cell(local_max)
	if project_models_to_ground:
		min_cell.y = 0
		max_cell.y = 0

	for x in range(min_cell.x, max_cell.x + 1):
		for y in range(min_cell.y, max_cell.y + 1):
			for z in range(min_cell.z, max_cell.z + 1):
				result[Vector3i(x, y, z)] = true


func _bounds_min_cell(bounds_min: Vector3) -> Vector3i:
	return Vector3i(
		floori(
			(bounds_min.x + cell_size.x * 0.5) / cell_size.x
			+ CELL_BOUNDARY_EPSILON
		),
		floori(
			(bounds_min.y + cell_size.y * 0.5) / cell_size.y
			+ CELL_BOUNDARY_EPSILON
		),
		floori(
			(bounds_min.z + cell_size.z * 0.5) / cell_size.z
			+ CELL_BOUNDARY_EPSILON
		),
	)


func _bounds_max_cell(bounds_max: Vector3) -> Vector3i:
	return Vector3i(
		ceili(
			(bounds_max.x - cell_size.x * 0.5) / cell_size.x
			- CELL_BOUNDARY_EPSILON
		),
		ceili(
			(bounds_max.y - cell_size.y * 0.5) / cell_size.y
			- CELL_BOUNDARY_EPSILON
		),
		ceili(
			(bounds_max.z - cell_size.z * 0.5) / cell_size.z
			- CELL_BOUNDARY_EPSILON
		),
	)


func _cell_less_than(a: Vector3i, b: Vector3i) -> bool:
	if a.y != b.y:
		return a.y < b.y
	if a.z != b.z:
		return a.z < b.z
	return a.x < b.x
