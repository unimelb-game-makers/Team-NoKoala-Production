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

func _ready() -> void:
	# TODO: fix this -> not great practice I don't think
	if grid == null:
		grid = get_tree().get_first_node_in_group("grid") as Grid

func _physics_process(delta: float) -> void:
	tick(delta)

func add_item(item: FactoryItem, progress: float = 0.0) -> void:
	items_on_belt.append({"item": item, "progress": progress, "waiting": false})

func tick(delta: float) -> void:
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

func _on_item_detector_area_entered(area: Area3D) -> void:
	var item := area.owner as FactoryItem
	if item == null || not is_placed:
		return
	if item.try_claim(self):
		print("added item")
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
	item.release_claim()
	var forward_cell := block_data.root_cell + _forward_direction()
	if grid:
		item.global_position = grid.cell_to_world(forward_cell)
	else:
		item.global_position = follow.global_transform.origin
