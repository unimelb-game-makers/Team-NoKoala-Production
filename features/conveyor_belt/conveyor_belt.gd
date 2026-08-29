class_name ConveyorBelt
extends Block

@export var speed: float = 1.0
@onready var path: Path3D = $Path3D
@onready var follow: PathFollow3D = $Path3D/PathFollow3D

var items_on_belt: Array[Dictionary] = []
var is_placed: bool = false
var grid: Grid

var is_corner: bool = false # case 1: forwards leads to empty
var is_straight_corner: bool = false # case 2: forwards leads to belt w/ diff rotation

func _ready() -> void:
	# TODO: fix this -> not great practice I don't think
	if grid == null:
		grid = get_tree().get_first_node_in_group("grid") as Grid

func _physics_process(delta: float) -> void:
	tick(delta)

func add_item(item: FactoryItem, progress: float = 0.0) -> void:
	items_on_belt.append({"item": item, "progress": progress})

func tick(delta: float) -> void:
	for item in items_on_belt:
		item.progress += speed * delta
		follow.progress = item.progress
		item.item.global_transform = follow.global_transform
	
	var finished: Array[Dictionary] = []
	for item in items_on_belt:
		var progress = item.progress
		# only check this halfway progress once
		if progress >= path.curve.get_baked_length() / 2:
			var _next := _get_next_belt()
			if is_corner:
				_process_end(item)
			if is_straight_corner:
				_process_end(item, 0.5, false)
		if progress >= path.curve.get_baked_length():
			finished.append(item)
	
	for item in finished:
		_process_end(item)

func _process_end(item: Dictionary, extra: float = 0.0, from_full_length: bool = true) -> void:
	items_on_belt.erase(item)
	var overflow: float
	if from_full_length:
		overflow = item.progress - path.curve.get_baked_length() + extra
	else:
		overflow = extra
	_hand_off(item.item, overflow)

func _on_item_detector_area_entered(area: Area3D) -> void:
	var item := area.owner as FactoryItem
	if item == null || not is_placed:
		return
	if item.try_claim(self):
		print("added item")
		add_item(item)

func _hand_off(item: FactoryItem, overflow: float = 0.0) -> void:
	var next := _get_next_belt()
	if next:
		if (is_corner):
			overflow += 0.5
		next.add_item(item, overflow)
	else:
		_drop_item(item)

func _get_next_belt() -> ConveyorBelt:
	if grid == null:
		return null
	var forward_cell := block_data.root_cell + _forward_direction()
	var forward_node := grid.get_block_node_at(forward_cell)
	var forward_belt := forward_node as ConveyorBelt
	# TODO: fix this so it can't accept something coming from the opposite dir
	if forward_belt:
		if forward_node.block_data.block_rotation == self.block_data.block_rotation:
			is_corner = false
			is_straight_corner = false
		else:
			print("case 2")
			is_corner = false
			is_straight_corner = true
		return forward_belt
	# no belt straight -> check for a belt to either side that can accept it
	for side_dir in _side_directions():
		var side_cell = block_data.root_cell + side_dir
		var side_belt = grid.get_block_node_at(side_cell) as ConveyorBelt
		if side_belt:
			is_corner = true
			is_straight_corner = false
			return side_belt
	return null

func _side_directions() -> Array[Vector3i]:
	var fwd = _forward_direction()
	# perpendicular to forward: rotate 90 degrees either way
	return [Vector3i(-fwd.z, fwd.y, fwd.x), Vector3i(fwd.z, fwd.y, -fwd.x)]

## Only accept the side belt as "next" if continues away (not back to the same)
func _accepts_from(other: ConveyorBelt, direction_to_other: Vector3i) -> bool:
	var incoming_dir = -direction_to_other
	return other._forward_direction() != incoming_dir

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
