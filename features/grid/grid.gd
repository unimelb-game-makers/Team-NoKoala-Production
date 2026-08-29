class_name Grid
extends GridMap

var grid_data: GridData = GridData.new()

## Moves a block to a new cell position if placement is valid.
func move_block(
	block: Block,
	cell: Vector3i,
	visual_root: Node3D = null,
) -> bool:
	remove_block(block)
	block.block_data.root_cell = cell
	var can_place = grid_data.add_block(block.block_data, block)
	if can_place:
		move_block_visual(visual_root if visual_root != null else block, cell)
	return can_place

## Adds a block to the grid if placement is valid.
func add_block(block: Block, visual_root: Node3D = null) -> bool:
	var can_place = grid_data.add_block(block.block_data, block)
	if can_place:
		add_block_visual(visual_root if visual_root != null else block)
	return can_place

## Removes a block from the grid data.
func remove_block(block: Block):
	grid_data.remove_block(block.block_data)

func world_to_cell(world_position: Vector3) -> Vector3i:
	return local_to_map(to_local(world_position))

func cell_to_world(cell: Vector3i) -> Vector3:
	return to_global(map_to_local(cell))

## Updates the visual position of a block to match grid coordinates.
## This function doesn't update grid data
func move_block_visual(visual_root: Node3D, cell: Vector3i):
	var local_pos = map_to_local(cell)
	visual_root.position = local_pos

## Adds a block as a child node for visual rendering.
## This function doesn't update grid data
func add_block_visual(visual_root: Node3D):
	add_child(visual_root)

func get_block_node_at(cell: Vector3i) -> Block:
	var cell_data := grid_data.get_cell_data(cell)
	return cell_data.node if cell_data != null else null
