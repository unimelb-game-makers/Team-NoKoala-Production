class_name GridData

class GridCellData:
	enum Type { 
		NORMAL,
	}

	var type: Type
	var block: BlockData
	
	func _init(p_type: Type):
		type = p_type
		block = null

var _grid: Dictionary[Vector3i, GridCellData] = {}
# the dictionary of cells occupied by a block
var _cells_by_block: Dictionary[BlockData, Array] = {}

func _init() -> void:
	# TODO: replace the hardcoded ranges 
	for x in range(-50, 50):
		for z in range(-50, 50):
			_grid[Vector3i(x, 0, z)] = GridCellData.new(GridCellData.Type.NORMAL)

func get_cells() -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	for cell: Vector3i in _grid:
		cells.append(cell)
	return cells
	
func get_cells_by_type(cell_type: GridCellData.Type) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []

	for cell: Vector3i in _grid:
		if _grid[cell].type == cell_type:
			cells.append(cell)

	return cells

## Returns null if the cell is outside of play space
func get_cell_data(cell: Vector3i) -> GridCellData:
	return _grid.get(cell)

## Returns true if the block can be placed at its current root_cell / rotation
## without overlapping another block or leaving the play space.
func can_place_block(block: BlockData) -> bool:
	for cell in block.blocking_cells():
		var cell_data := get_cell_data(cell)
		if cell_data == null:
			return false
		if cell_data.block != null and cell_data.block != block:
			return false
	return true

func add_block(block: BlockData) -> bool:
	if not can_place_block(block):
		return false

	var registered_cells: Array[Vector3i] = []
	for cell in block.blocking_cells():
		var cell_data := get_cell_data(cell)
		if cell_data != null:
			cell_data.block = block
			registered_cells.append(cell)
	_cells_by_block[block] = registered_cells
	 
	block.is_placed = true
	
	return true
				
func remove_block(block: BlockData) -> Array[Vector3i]:
	var removed_cells: Array[Vector3i] = []
	var registered_cells: Array = _cells_by_block.get(block, [])
	for cell: Vector3i in registered_cells:
		var cell_data := get_cell_data(cell)
		if cell_data == null:
			continue
		if cell_data.block == block:
			cell_data.block = null
			removed_cells.append(cell)

	_cells_by_block.erase(block)
	block.is_placed = false
	return removed_cells
