class_name GridData

const DEFAULT_PLAYABLE_REGION := Rect2i(-100, -100, 200, 200)

## Rect2i X/Y correspond to world-grid X/Z. Every cell inside it (at y = 0)
## is part of the play space; nothing is allocated per cell.
var playable_region: Rect2i
# sparse map of occupied cells to the block occupying them
var _blocks_by_cell: Dictionary[Vector3i, BlockData] = {}
# the dictionary of cells occupied by a block
var _cells_by_block: Dictionary[BlockData, Array] = {}


func _init(p_playable_region := DEFAULT_PLAYABLE_REGION) -> void:
	playable_region = p_playable_region

## Whether the cell is inside the play space.
func is_in_bounds(cell: Vector3i) -> bool:
	return cell.y == 0 and playable_region.has_point(Vector2i(cell.x, cell.z))

## Returns the block occupying the cell, or null if the cell is empty or
## outside of play space.
func get_block_at(cell: Vector3i) -> BlockData:
	return _blocks_by_cell.get(cell)

## Returns every cell currently occupied by a block.
func get_occupied_cells() -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	cells.assign(_blocks_by_cell.keys())
	return cells

## Whether this block can occupy one blocking cell, including its own cell.
func can_occupy_cell(block: BlockData, cell: Vector3i) -> bool:
	if not is_in_bounds(cell):
		return false
	var occupant: BlockData = _blocks_by_cell.get(cell)
	return occupant == null or occupant == block

## Returns true if the block can be placed at its current root_cell / rotation
## without overlapping another block or leaving the play space.
func can_place_block(block: BlockData) -> bool:
	for cell in block.blocking_cells():
		if not can_occupy_cell(block, cell):
			return false
	return true

func add_block(block: BlockData) -> bool:
	if not can_place_block(block):
		return false

	var registered_cells: Array[Vector3i] = []
	for cell in block.blocking_cells():
		_blocks_by_cell[cell] = block
		registered_cells.append(cell)
	_cells_by_block[block] = registered_cells

	block.is_placed = true

	return true

func remove_block(block: BlockData) -> Array[Vector3i]:
	var removed_cells: Array[Vector3i] = []
	var registered_cells: Array = _cells_by_block.get(block, [])
	for cell: Vector3i in registered_cells:
		if _blocks_by_cell.get(cell) == block:
			_blocks_by_cell.erase(cell)
			removed_cells.append(cell)

	_cells_by_block.erase(block)
	block.is_placed = false
	return removed_cells
