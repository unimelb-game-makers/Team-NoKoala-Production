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

func add_block(block: BlockData) -> bool:
	var can_place := true
	var blocking_cells := block.blocking_cells()

	for cell in blocking_cells:
		var cell_data := get_cell_data(cell)
		if cell_data != null and cell_data.block != null:
			can_place = false

	if not can_place:
		return false

	for cell in blocking_cells:
		var cell_data := get_cell_data(cell)
		if cell_data != null:
			cell_data.block = block
	 
	block.is_placed = true

	return true
				
func remove_block(block: BlockData) -> void:
	if not block.is_placed:
		return

	var blocking_cells := block.blocking_cells()
	for cell in blocking_cells:
		var cell_data := get_cell_data(cell)
		if cell_data != null and cell_data.block == block:
			cell_data.block = null

	block.is_placed = false
