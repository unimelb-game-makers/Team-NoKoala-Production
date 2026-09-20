@tool
class_name Grid
extends GridMap

var grid_data: GridData = GridData.new()
var _blocks_by_cell: Dictionary[Vector3i, Array] = {}

signal grid_changed(affected_cells: Array)

func _ready() -> void:
	grid_data = GridData.new()

	add_to_group("grid")

	for node in get_tree().get_nodes_in_group("resource_area"):
		var assembly := node as ResourceAreaMachineAssembly
		if assembly == null:
			continue
		if assembly.grid != null and assembly.grid != self:
			continue
		assembly.grid = self
		assembly.block.block_data = assembly.block_data
		move_block(assembly.block, assembly.block.block_data.root_cell)


## Moves a block to a new cell position if placement is valid.
func move_block(
	block: Block,
	cell: Vector3i,
) -> bool:
	remove_block(block)
	block.block_data.root_cell = cell
	var can_place := register_block(block)
	if can_place:
		move_block_visual(block, cell)
	return can_place

## Returns true if the block can be placed at the given cell (using its current
## rotation) without overlapping another block or leaving the play space.
## Does not modify the grid or the block.
func can_place_block_at(block: Block, cell: Vector3i) -> bool:
	var previous_cell := block.block_data.root_cell
	block.block_data.root_cell = cell
	var result := grid_data.can_place_block(block.block_data)
	block.block_data.root_cell = previous_cell
	return result

func can_occupy_cell(block_data: BlockData, cell: Vector3i) -> bool:
	return grid_data.can_occupy_cell(block_data, cell)

## Registers a block without changing its scene-tree parent or transform.
func register_block(block: Block) -> bool:
	var can_place := grid_data.add_block(block.block_data)
	if can_place:
		_index_block(block)
		var exit_callback := _on_registered_block_exiting.bind(block)
		if not block.tree_exiting.is_connected(exit_callback):
			block.tree_exiting.connect(exit_callback)
		grid_changed.emit(block.block_data.blocking_cells())
	return can_place

## Unregisters a block without changing its scene-tree parent or transform.
func unregister_block(
	block: Block,
	registered_data: BlockData = null,
) -> void:
	var exit_callback := _on_registered_block_exiting.bind(block)
	if block.tree_exiting.is_connected(exit_callback):
		block.tree_exiting.disconnect(exit_callback)
	var block_data := registered_data if registered_data != null else block.block_data
	var affected_cells := grid_data.remove_block(block_data)
	for cell in _blocks_by_cell.keys():
		var blocks: Array = _blocks_by_cell.get(cell, [])
		if not blocks.has(block):
			continue
		blocks.erase(block)
		if not affected_cells.has(cell):
			affected_cells.append(cell)
		if blocks.is_empty():
			_blocks_by_cell.erase(cell)
		else:
			_blocks_by_cell[cell] = blocks
	if not affected_cells.is_empty():
		grid_changed.emit(affected_cells)

func _on_registered_block_exiting(block: Block) -> void:
	unregister_block(block)

## Removes a block from the grid data and the coordinate index.
func remove_block(block: Block) -> void:
	unregister_block(block)

func get_blocks_at(cell: Vector3i) -> Array[Block]:
	if not _blocks_by_cell.has(cell):
		return []

	var result: Array[Block] = []
	var pruned := false
	for entry in _blocks_by_cell[cell]:
		if is_instance_valid(entry):
			result.append(entry)
		else:
			pruned = true

	if pruned:
		if result.is_empty():
			_blocks_by_cell.erase(cell)
		else:
			_blocks_by_cell[cell] = result

	return result

func _index_block(block: Block) -> void:
	for cell in block.block_data.occupied_cells():
		if grid_data.get_cell_data(cell) == null:
			continue
		var blocks: Array = _blocks_by_cell.get(cell, [])
		if not blocks.has(block):
			blocks.append(block)
		_blocks_by_cell[cell] = blocks

func world_to_cell(world_position: Vector3) -> Vector3i:
	return local_to_map(to_local(world_position))

func cell_to_world(cell: Vector3i) -> Vector3:
	return to_global(map_to_local(cell))

func world_to_grid_rotation(world_rotation_degrees: float) -> BlockData.Rotation:
	var relative_rotation := wrapf(
		world_rotation_degrees - global_rotation_degrees.y,
		0.0,
		360.0,
	)
	var snapped_rotation := wrapi(
		roundi(relative_rotation / 90.0) * 90,
		0,
		360,
	)
	return snapped_rotation as BlockData.Rotation

func grid_to_world_rotation(grid_rotation: BlockData.Rotation) -> float:
	return global_rotation_degrees.y + float(grid_rotation)

## Updates the visual position of a block to match grid coordinates.
## This function doesn't update grid data
func move_block_visual(block: Block, cell: Vector3i):
	block.get_transform_root().global_position = cell_to_world(cell)
