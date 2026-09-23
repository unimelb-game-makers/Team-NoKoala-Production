## gizmos that visualise blockdata

@tool
class_name BlockCellGizmo
extends Node3D

@export var block: Block
@export var grid: Grid
@export var cell_size := Vector3.ONE
@export_range(0.01, 1.0, 0.01) var cell_inset := 0.08
@export_range(0.01, 1.0, 0.01) var gizmo_height := 0.08
@export var occupied_color := Color(0.1, 0.75, 1.0, 0.75)
@export var overlap_color := Color(0.0, 0.824, 0.345, 0.75)
@export var conflict_color := Color(1.0, 0.12, 0.12, 0.75)

@export_tool_button("Refresh Gizmo", "Callable")
var refresh_button := refresh

var _watched_block_data: BlockData
var _watched_grid: Grid
var _cells: Array[Vector3i] = []
var _instance_by_world_cell: Dictionary[Vector3i, int] = {}
var _overlap_cells: Dictionary[Vector3i, bool] = {}
var _multimesh_instance: MultiMeshInstance3D
var _multimesh: MultiMesh
var _box_mesh: BoxMesh
var _material: StandardMaterial3D
var _block_data_refresh_pending := false


func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	if grid == null:
		grid = get_tree().get_first_node_in_group("grid") as Grid


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	if grid != _watched_grid:
		_watch_grid(grid)
	var block_data := block.block_data if block != null else null
	if block_data != _watched_block_data:
		_watch_block_data(block_data)
	if _block_data_refresh_pending:
		_block_data_refresh_pending = false
		_apply_block_data_changes()


func _exit_tree() -> void:
	_disconnect_block_data()
	_disconnect_grid()


func refresh() -> void:
	if not Engine.is_editor_hint() or _watched_block_data == null:
		_clear_instances()
		return

	_update_overlap_lookup()
	_rebuild_instances()



# functions for rendering
func _rebuild_instances() -> void:
	_ensure_multimesh()
	_cells.assign(_watched_block_data.footprint)
	_instance_by_world_cell.clear()

	_multimesh.instance_count = _cells.size()

	var y_offset := gizmo_height * 0.5
	for index in _cells.size():
		var cell := _cells[index]
		var position := Vector3(cell) * cell_size
		position.y += y_offset
		_multimesh.set_instance_transform(
			index,
			Transform3D(Basis.IDENTITY, position),
		)

	_rebuild_world_cell_index()
	_refresh_all_colors()


func _ensure_multimesh() -> void:
	if not is_instance_valid(_multimesh_instance):
		_multimesh_instance = MultiMeshInstance3D.new()
		_multimesh_instance.name = "Cells"
		_multimesh_instance.cast_shadow = (
			GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		)
		_multimesh = MultiMesh.new()
		_multimesh_instance.multimesh = _multimesh
		_multimesh.transform_format = MultiMesh.TRANSFORM_3D
		_multimesh.use_colors = true

		add_child(_multimesh_instance)

	for child in get_children():
		if (
			child != _multimesh_instance
			and child is MeshInstance3D
		):
			child.queue_free()


	if _box_mesh == null:
		_box_mesh = BoxMesh.new()
		_multimesh.mesh = _box_mesh
	_box_mesh.size = Vector3(
		maxf(cell_size.x - cell_inset, 0.01),
		gizmo_height,
		maxf(cell_size.z - cell_inset, 0.01),
	)

	if _material == null:
		_material = StandardMaterial3D.new()
		_material.albedo_color = Color.WHITE
		_material.vertex_color_use_as_albedo = true
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_material.no_depth_test = true
		_material.render_priority = 127
		_box_mesh.material = _material


func _refresh_all_colors() -> void:
	if _multimesh == null:
		return
	for index in _cells.size():
		_multimesh.set_instance_color(index, _color_for_cell(_cells[index]))


func _refresh_affected_colors(affected_cells: Array) -> void:
	if _multimesh == null:
		return
	for world_cell in affected_cells:
		var index: int = _instance_by_world_cell.get(world_cell, -1)
		if index >= 0:
			_multimesh.set_instance_color(
				index,
				_color_for_cell(_cells[index]),
			)


func _color_for_cell(cell: Vector3i) -> Color:
	if _overlap_cells.has(cell):
		return overlap_color
	if _watched_block_data!= null and grid != null and not grid.can_occupy_cell(
		_watched_block_data,
		_watched_block_data.world_cell_for_offset(cell),
	):
		return conflict_color
	return occupied_color


func _update_overlap_lookup() -> void:
	_overlap_cells.clear()
	for cell in _watched_block_data.overlap_cells:
		_overlap_cells[cell] = true


func _rebuild_world_cell_index() -> void:
	_instance_by_world_cell.clear()
	if _watched_block_data == null:
		return
	for index in _cells.size():
		_instance_by_world_cell[
			_watched_block_data.world_cell_for_offset(_cells[index])
		] = index




# functions for watch block changes

func _on_block_data_changed() -> void:
	_block_data_refresh_pending = true


func _apply_block_data_changes() -> void:
	if _watched_block_data == null:
		return

	_update_overlap_lookup()
	if _cells != _watched_block_data.footprint:
		_rebuild_instances()
		return

	# Position or rotation changes only affect world-cell conflict lookup.
	_rebuild_world_cell_index()
	_refresh_all_colors()


func _watch_block_data(block_data: BlockData) -> void:
	_disconnect_block_data()
	_watched_block_data = block_data
	_block_data_refresh_pending = false
	if _watched_block_data != null:
		_watched_block_data.changed.connect(_on_block_data_changed)
	refresh()


func _watch_grid(next_grid: Grid) -> void:
	_disconnect_grid()
	_watched_grid = next_grid
	if is_instance_valid(_watched_grid):
		_watched_grid.grid_changed.connect(_on_grid_changed)
	_rebuild_world_cell_index()
	_refresh_all_colors()


func _on_grid_changed(affected_cells: Array) -> void:
	_refresh_affected_colors(affected_cells)


func _clear_instances() -> void:
	_cells.clear()
	_instance_by_world_cell.clear()
	_overlap_cells.clear()
	if _multimesh != null:
		_multimesh.instance_count = 0


func _disconnect_grid() -> void:
	if (
		is_instance_valid(_watched_grid)
		and _watched_grid.grid_changed.is_connected(_on_grid_changed)
	):
		_watched_grid.grid_changed.disconnect(_on_grid_changed)
	_watched_grid = null


func _disconnect_block_data() -> void:
	if (
		_watched_block_data != null
		and _watched_block_data.changed.is_connected(_on_block_data_changed)
	):
		_watched_block_data.changed.disconnect(_on_block_data_changed)
	_watched_block_data = null
