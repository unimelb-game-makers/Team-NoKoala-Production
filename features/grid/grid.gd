class_name Grid
extends GridMap

var grid_data: GridData = GridData.new()
var _blocks_by_cell: Dictionary[Vector3i, Block] = {}

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
	return can_place

## Adds a block to the grid if placement is valid.
func add_block(block: Block) -> bool:
	var can_place = grid_data.add_block(block.block_data)
	if can_place:
		_index_block(block)
		add_block_visual(block)
	return can_place

## Removes a block from the grid data.
func remove_block(block: Block) -> void:
	var blocking_cells := block.block_data.blocking_cells()
	grid_data.remove_block(block.block_data)
	for cell in blocking_cells:
		if _blocks_by_cell.get(cell) == block:
			_blocks_by_cell.erase(cell)

## Returns the placed block instance at a blocking cell, or null.
func get_block_at(cell: Vector3i) -> Block:
	return _blocks_by_cell.get(cell)

func _index_block(block: Block) -> void:
	for cell in block.block_data.blocking_cells():
		var cell_data := grid_data.get_cell_data(cell)
		if cell_data != null and cell_data.block == block.block_data:
			_blocks_by_cell[cell] = block

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
