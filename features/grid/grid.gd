class_name Grid
extends GridMap

var grid_data: GridData = GridData.new()

## Moves a block to a new cell position if placement is valid.
func move_block(block: Block, cell: Vector3i) -> bool:
	remove_block(block)
	block.root_cell = cell
	var can_place = grid_data.add_block(block)
	if can_place:
		move_block_visual(block, cell)
	return can_place

## Adds a block to the grid if placement is valid.
func add_block(block: Block) -> bool:
	var can_place = grid_data.add_block(block)
	if can_place:
		add_block_visual(block)
	return can_place

## Removes a block from the grid data.
func remove_block(block: Block):
	grid_data.remove_block(block)

## Updates the visual position of a block to match grid coordinates.
## This function doesn't update grid data
func move_block_visual(block: Block, cell: Vector3i):
	var local_pos = map_to_local(cell)
	block.position = local_pos

## Adds a block as a child node for visual rendering.
## This function doesn't update grid data
func add_block_visual(block: Block):
	add_child(block)
