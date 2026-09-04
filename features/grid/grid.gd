class_name Grid
extends GridMap

var grid_data: GridData = GridData.new()
var _blocks_by_cell: Dictionary[Vector3i, Array] = {}

signal grid_changed(affected_cells: Array)

func _ready() -> void:
	add_to_group("grid")


## Moves a block to a new cell position if placement is valid.
func move_block(
	block: Block,
	cell: Vector3i,
) -> bool:
	remove_block(block)
	block.block_data.root_cell = cell
	var can_place = grid_data.add_block(block.block_data)
	if can_place:
		_index_block(block)
		move_block_visual(block, cell)
		grid_changed.emit(block.block_data.blocking_cells())
	return can_place

## Adds a block to the grid if placement is valid.
func add_block(block: Block) -> bool:
	var can_place = grid_data.add_block(block.block_data)
	if can_place:
		_index_block(block)
		add_block_visual(block)
		grid_changed.emit(block.block_data.blocking_cells())
	return can_place

## Removes a block from the grid data and the coordinate index.
func remove_block(block: Block) -> void:
	var occupied_cells := block.block_data.occupied_cells()
	if not block.block_data.is_placed:
		return
	grid_data.remove_block(block.block_data)
	for cell in occupied_cells:
		var blocks: Array = _blocks_by_cell.get(cell, [])
		blocks.erase(block)
		if blocks.is_empty():
			_blocks_by_cell.erase(cell)
		else:
			_blocks_by_cell[cell] = blocks
	grid_changed.emit(occupied_cells)

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

## Updates the visual position of a block to match grid coordinates.
## This function doesn't update grid data
func move_block_visual(block: Block, cell: Vector3i):
	var local_pos = map_to_local(cell)
	block.get_transform_root().position = local_pos

## Adds a block as a child node for visual rendering.
## This function doesn't update grid data
func add_block_visual(block: Block):
	add_child(block.get_transform_root())
