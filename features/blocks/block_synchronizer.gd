@tool
class_name BlockSynchronizer
extends Node

@export var block: Block
@export var grid: Grid
@export var auto_snap_position := true
@export var auto_snap_rotation := true

@export_tool_button("Sync Position", "Callable")
var sync_position_button := sync_position_to_block_data

@export_tool_button("Sync Rotation", "Callable")
var sync_rotation_button := sync_rotation_to_block_data

var _has_last_position := false
var _last_position := Vector3.ZERO
var _has_last_rotation := false
var _last_rotation := 0.0


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() or block == null or grid == null:
		return

	var transform_root := block.get_transform_root()
	if not _is_selected(transform_root):
		snap_to_grid()

	var current_position := transform_root.global_position
	var current_rotation := transform_root.global_rotation_degrees.y
	var position_changed := (
		not _has_last_position
		or not current_position.is_equal_approx(_last_position)
	)
	var rotation_changed := (
		not _has_last_rotation
		or not is_equal_approx(current_rotation, _last_rotation)
	)

	if position_changed:
		sync_position_to_block_data()
	if rotation_changed:
		sync_rotation_to_block_data()


func sync_position_to_block_data() -> void:
	if not Engine.is_editor_hint() or block == null or grid == null:
		return

	var transform_root := block.get_transform_root()
	_last_position = transform_root.global_position
	_has_last_position = true
	if block.block_data != null:
		block.block_data.root_cell = grid.world_to_cell(_last_position)
		block.block_data.emit_changed()


func sync_rotation_to_block_data() -> void:
	if not Engine.is_editor_hint() or block == null or grid == null:
		return

	var transform_root := block.get_transform_root()
	_last_rotation = transform_root.global_rotation_degrees.y
	_has_last_rotation = true
	if block.block_data != null:
		block.block_data.block_rotation = grid.world_to_grid_rotation(_last_rotation)
		block.block_data.emit_changed()


func snap_to_grid() -> void:
	var transform_root := block.get_transform_root()
	if auto_snap_position:
		var current_cell := grid.world_to_cell(transform_root.global_position)
		transform_root.global_position = grid.cell_to_world(current_cell)
	if auto_snap_rotation:
		var grid_rotation := grid.world_to_grid_rotation(
			transform_root.global_rotation_degrees.y,
		)
		transform_root.global_rotation_degrees.y = (
			grid.grid_to_world_rotation(grid_rotation)
		)


func _is_selected(node: Node) -> bool:
	return EditorInterface.get_selection().get_selected_nodes().has(node)
