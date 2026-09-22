@tool
class_name BlockCellGizmo
extends Node3D

@export var block: Block
@export var grid: Grid
@export var cell_size := Vector3.ONE
@export_range(0.01, 1.0, 0.01) var cell_inset := 0.08
@export_range(0.01, 1.0, 0.01) var gizmo_height := 0.08
@export var occupied_color := Color(1.0, 0.2, 0.15, 0.35)
@export var overlap_color := Color(0.1, 0.75, 1.0, 0.35)
@export var conflict_color := Color(1.0, 0.12, 0.12, 0.7)

@export_tool_button("Refresh Gizmo", "Callable")
var refresh_button := refresh

var _watched_block_data: BlockData
var _watched_grid: Grid



func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return 
	if grid != _watched_grid:
		_watch_grid(grid)
	var block_data := block.block_data if block != null else null
	if block_data != _watched_block_data:
		_watch_block_data(block_data)


func _exit_tree() -> void:
	_disconnect_block_data()
	_disconnect_grid()


func refresh() -> void:
	for child in get_children():
		child.queue_free()

	if not Engine.is_editor_hint() or _watched_block_data == null:
		return

	for cell in _watched_block_data.footprint:
		_add_cell(cell, _color_for_cell(cell))


func _color_for_cell(cell: Vector3i) -> Color:
	if _watched_block_data == null:
		return occupied_color
	if _watched_block_data.overlap_cells.has(cell):
		return overlap_color
	if grid != null and not grid.can_occupy_cell(
		_watched_block_data,
		_watched_block_data.world_cell_for_offset(cell),
		):
		return conflict_color
	return occupied_color


func _add_cell(cell: Vector3i, color: Color) -> void:
	var box := BoxMesh.new()
	box.size = Vector3(
		maxf(cell_size.x - cell_inset, 0.01),
		gizmo_height,
		maxf(cell_size.z - cell_inset, 0.01),
	)

	var marker := MeshInstance3D.new()
	marker.name = "Cell_%d_%d_%d" % [cell.x, cell.y, cell.z]
	marker.mesh = box
	marker.position = Vector3(cell) * cell_size
	marker.position.y += box.size.y * 0.5
	marker.material_override = _create_material(color)
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(marker)


func _create_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.no_depth_test = true
	material.render_priority = 127 if color == conflict_color else 10
	return material


func _watch_block_data(block_data: BlockData) -> void:
	_disconnect_block_data()
	_watched_block_data = block_data
	if _watched_block_data != null:
		_watched_block_data.changed.connect(refresh)
	refresh()


func _watch_grid(next_grid: Grid) -> void:
	_disconnect_grid()
	_watched_grid = next_grid
	if is_instance_valid(_watched_grid):
		_watched_grid.grid_changed.connect(_on_grid_changed)
	refresh()


func _on_grid_changed(affected_cells: Array) -> void:
	if _watched_block_data == null:
		return
	for cell in _watched_block_data.blocking_cells():
		if affected_cells.has(cell):
			refresh()
			return


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
		and _watched_block_data.changed.is_connected(refresh)
	):
		_watched_block_data.changed.disconnect(refresh)
	_watched_block_data = null
