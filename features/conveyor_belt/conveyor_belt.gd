class_name ConveyorBelt
extends Block

@export var speed: float = 1.0
@onready var path: Path3D = $Path3D
@onready var follow: PathFollow3D = $Path3D/PathFollow3D
@onready var middle: Node3D = $Middle

var next: ConveyorBelt = null
var items_on_belt: Array[Dictionary] = []
var is_placed: bool = false
var grid: Grid

var is_straight_corner: bool = false # case 2: forwards leads to belt w/ diff rotation

func initialize(p_grid: Grid) -> void:
	assert(p_grid != null, "ConveyorBelt requires a Grid")
	grid = p_grid

func add_item(item: FactoryItem, progress: float = 0.0) -> void:
	items_on_belt.append({"item": item, "progress": progress, "waiting": false})

func tick(delta: float, factory_manager: FactoryManager) -> void:
	_detect_indexed_items(factory_manager)

	for item in items_on_belt:
		if item.get("waiting", false):
			continue
		item.progress += speed * delta
		follow.progress = item.progress
		item.item.global_transform = follow.global_transform
	
	var finished: Array[Dictionary] = []
	for item in items_on_belt:
		if item.get("waiting", false):
			continue
		var progress = item.progress
		if progress >= path.curve.get_baked_length():
			finished.append(item)
	
	for item in finished:
		_process_end(item)

func _process_end(item: Dictionary, extra: float = 0.0) -> void:
	next = _get_next_belt()
	if next == null and _forward_has_conflict():
		item.progress = path.curve.get_baked_length()
		follow.progress = item.progress
		item.item.global_transform = follow.global_transform
		item["waiting"] = true
		return

	items_on_belt.erase(item)
	_hand_off(item.item, extra)

func _detect_indexed_items(factory_manager: FactoryManager) -> void:
	if not is_placed or factory_manager == null:
		return

	for processable in factory_manager.get_processables_at(
		block_data.root_cell
	):
		var item := processable as FactoryItem
		if item != null and item.try_claim(self):
			add_item(item)

func _forward_has_conflict() -> bool:
	if grid == null:
		return false
	var forward_cell := block_data.root_cell + _forward_direction()
	var forward_belt := grid.get_block_node_at(forward_cell) as ConveyorBelt
	return forward_belt != null and _conflicting_direction(forward_belt)

func _hand_off(item: FactoryItem, overflow: float = 0.0) -> void:
	next = _get_next_belt()
	if next:
		if is_straight_corner:
			overflow += 0.5
			var target_pos: Vector3 = next.middle.global_position
			var tween = create_tween()
			tween.tween_property(item, "global_position", target_pos, 0.6)
			await tween.finished
		next.add_item(item, overflow)
	else:
		_drop_item(item)

func _get_next_belt() -> ConveyorBelt:
	if grid == null:
		return null
	var forward_cell := block_data.root_cell + _forward_direction()
	var forward_node := grid.get_block_node_at(forward_cell)
	var forward_belt := forward_node as ConveyorBelt
	if forward_belt:
		if _conflicting_direction(forward_belt):
			return null
		if _same_direction(forward_belt):
			is_straight_corner = false
		else:
			is_straight_corner = true
		return forward_belt
	return null

func _same_direction(other: ConveyorBelt) -> bool:
	return other.block_data.block_rotation == self.block_data.block_rotation

func _conflicting_direction(other: ConveyorBelt) -> bool:
	return other._forward_direction() + self._forward_direction() == Vector3i.ZERO

func _forward_direction() -> Vector3i:
	const DIRECTIONS := {
		BlockData.Rotation.DEG0:   Vector3i(0, 0, -1),
		BlockData.Rotation.DEG90:  Vector3i(-1, 0, 0),
		BlockData.Rotation.DEG180: Vector3i(0, 0, 1),
		BlockData.Rotation.DEG270: Vector3i(1, 0, 0),
	}
	return DIRECTIONS[block_data.block_rotation]

func _drop_item(item: FactoryItem) -> void:
	var forward_cell := block_data.root_cell + _forward_direction()
	var drop_position := follow.global_transform.origin
	if grid:
		drop_position = grid.cell_to_world(forward_cell)
	item.global_position = drop_position
	item.drop_at(drop_position)
