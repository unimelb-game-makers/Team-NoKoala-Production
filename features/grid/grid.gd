class_name Grid
extends GridMap

var grid_data: GridData = GridData.new()

func move_block_to_cell(block: Block, cell: Vector3i, update_data: bool = true) -> bool:
	var can_place := true
	if update_data:
		grid_data.remove_block(block)
		block.root_cell = cell
		can_place = grid_data.add_block(block)
	
	if can_place:
		var local_pos = map_to_local(cell)
		var global_pos = to_global(local_pos)
		block.global_position = global_pos
	
	return can_place