class_name BlockData
extends Resource

enum BlockType { 
	NORMAL,
}

enum Rotation {
	DEG0 = 0,
	DEG90 = 90,
	DEG180 = 180,
	DEG270 = 270,
}

@export var footprint: Array[Vector3i]
@export var overlap_cells: Array[Vector3i] = []
var block_rotation: Rotation = Rotation.DEG0
var is_placed: bool
var root_cell: Vector3i
var type: BlockType

func occupied_cells() -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	for delta in footprint:
		result.append(world_cell_for_offset(delta))
	return result

#returns cells that does not allow overlap
func blocking_cells() -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	for delta in footprint:
		if not overlap_cells.has(delta):
			result.append(world_cell_for_offset(delta))
	return result

func world_cell_for_offset(offset: Vector3i) -> Vector3i:
	return root_cell + _rotate_footprint_delta(offset)

func _rotate_footprint_delta(delta: Vector3i) -> Vector3i:
	match block_rotation:
		Rotation.DEG0:
			return delta
		Rotation.DEG90:
			return Vector3i(delta.z, delta.y, -delta.x)
		Rotation.DEG180:
			return Vector3i(-delta.x, delta.y, -delta.z)
		Rotation.DEG270:
			return Vector3i(-delta.z, delta.y, delta.x)
		_:
			assert(false, "Invalid block rotation")
			return delta

func switch_rotation() -> void:
	match block_rotation:
		Rotation.DEG0:
			block_rotation = Rotation.DEG90
		Rotation.DEG90:
			block_rotation = Rotation.DEG180
		Rotation.DEG180:
			block_rotation = Rotation.DEG270
		Rotation.DEG270:
			block_rotation = Rotation.DEG0
		_:
			assert(false, "Invalid block rotation")
