class_name ConveyorBelt
extends Block

@export var speed: float = 1.0
@onready var path: Path3D = $Path3D
@onready var follow: PathFollow3D = $Path3D/PathFollow3D
@onready var exit_area: Area3D = $ExitArea
@onready var forward_area: Area3D = $ForwardArea
@onready var back_area: Area3D = $BackArea

var items_on_belt: Array[Dictionary] = []
var neighbour: ConveyorBelt = null
var is_placed: bool = false
var grid: Grid

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
		if item.progress >= path.curve.get_baked_length():
			finished.append(item)
	
	for item in finished:
		items_on_belt.erase(item)
		var overflow: float = item.progress - path.curve.get_baked_length()
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
		next.add_item(item, overflow)
	else:
		_drop_item(item)

func _get_next_belt() -> ConveyorBelt:
	if grid == null:
		return null
	var forward_cell := block_data.root_cell + _forward_direction()
	var forward_belt := grid.get_block_node_at(forward_cell) as ConveyorBelt
	# TODO: fix this so it can't accept something coming from the opposite dir
	if forward_belt:
		return forward_belt
	# TODO: fix this so turning corner gets it to start at progress 50%
	# no belt straight -> check for a belt to either side that can accept it
	for side_dir in _side_directions():
		var side_cell = block_data.root_cell + side_dir
		var side_belt = grid.get_block_node_at(side_cell) as ConveyorBelt
		if side_belt and _accepts_from(side_belt, side_dir):
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
