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
	if grid == null:
		grid = get_tree().get_first_node_in_group("grid") as Grid

func _physics_process(delta: float) -> void:
	tick(delta)

func add_item(item: FactoryItem) -> void:
	items_on_belt.append({"item": item, "progress": 0.0})

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
		#_hand_off_to_next_segment(item.item)
		_hand_off(item.item)
		#_hand_off_to_neighbour(item.item)

func _hand_off_to_neighbour(item: FactoryItem) -> void:
	if neighbour:
		neighbour.add_item(item)

func set_neighbour(next: ConveyorBelt) -> void:
	neighbour = next

func _on_item_detector_area_entered(area: Area3D) -> void:
	var item := area.owner as FactoryItem
	if item == null || not is_placed:
		return
	if item.try_claim(self):
		print("added item")
		add_item(item)

func _hand_off(item: FactoryItem) -> void:
	var next := _get_next_belt()
	if next:
		next.add_item(item)
	else:
		_drop_item(item)

func _get_next_belt() -> ConveyorBelt:
	if grid == null:
		return null
	var forward_cell := block_data.root_cell + _forward_direction()
	return grid.get_block_node_at(forward_cell) as ConveyorBelt

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
