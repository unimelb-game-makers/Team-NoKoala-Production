class_name GridData

class GridTileData:
	enum Type { 
		NORMAL,
	}

	var type: Type
	var block: Block
	
	func _init(p_type: Type):
		type = p_type
		block = null

var _grid: Dictionary[Vector2i, GridTileData] = {}

func get_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in _grid:
		cells.append(cell)
	return cells
	
func get_cells_by_type(tile_type: GridTileData.Type) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []

	for cell: Vector2i in _grid:
		if _grid[cell].type == tile_type:
			cells.append(cell)

	return cells

## Returns null if the cell is outside of play space
func get_tile_data(cell: Vector2i) -> GridTileData:
	return _grid.get(cell)

func get_tile_datas() -> Array[GridTileData]:
	var tiles: Array[GridTileData] = _grid.values()
	return tiles

func add_block(block: Block) -> void:
	for segment_cell in block.segment_cells:
		var tile_data := get_tile_data(segment_cell)
		if tile_data != null:
			tile_data.block = block
				
func remove_block(block: Block) -> void:
	for segment_cell in block.segment_cells:
		var tile_data := get_tile_data(segment_cell)
		if tile_data != null:
			tile_data.block = null
