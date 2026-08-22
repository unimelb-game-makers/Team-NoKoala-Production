class_name GridData

class GridTileData:
	enum Type { 
		NORMAL,
	}

	var type: Type
	var block: BlockData
	
	func _init(p_type: Type):
		type = p_type
		block = null

var _grid: Dictionary[Vector3i, GridTileData] = {}

func _init() -> void:
	# TODO: replace the hardcoded ranges 
	for x in range(-50, 50):
		for z in range(-50, 50):
			_grid[Vector3i(x, 0, z)] = GridTileData.new(GridTileData.Type.NORMAL)

func get_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector3i in _grid:
		cells.append(cell)
	return cells
	
func get_cells_by_type(tile_type: GridTileData.Type) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []

	for cell: Vector3i in _grid:
		if _grid[cell].type == tile_type:
			cells.append(cell)

	return cells

## Returns null if the cell is outside of play space
func get_tile_data(cell: Vector3i) -> GridTileData:
	return _grid.get(cell)

func add_block(block: BlockData) -> bool:
	var can_place := true
	var occupied_cells := block.occupied_cells()

	for cell in occupied_cells:
		var tile_data := get_tile_data(cell)
		if tile_data != null and tile_data.block != null:
			can_place = false

	if not can_place:
		return false

	for cell in occupied_cells:
		var tile_data := get_tile_data(cell)
		if tile_data != null:
			tile_data.block = block
	 
	block.is_placed = true

	return true
				
func remove_block(block: BlockData) -> void:
	if not block.is_placed:
		return

	var occupied_cells := block.occupied_cells()
	for cell in occupied_cells:
		var tile_data := get_tile_data(cell)
		if tile_data != null and tile_data.block == block:
			tile_data.block = null

	block.is_placed = false
