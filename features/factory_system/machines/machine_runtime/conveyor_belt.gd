class_name ConveyorBelt
extends Machine

@export var speed: float = 1.0
@export var block: Block
@export var path: Path3D
@export var follow: PathFollow3D
@export var middle: Node3D

var items_on_belt: Array[Dictionary] = []

func is_straight_corner(other: ConveyorBelt) -> bool:
	return (
		other != null
		and not _same_direction(other)
		and not _conflicting_direction(other)
	)


func add_item(item: FactoryItem, progress: float = 0.5) -> void:
	items_on_belt.append({"item": item, "progress": progress, "waiting": false})

func factory_tick(delta: float, factory_manager: FactoryManager) -> void:
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
		_process_end(item, factory_manager)

func _process_end(item: Dictionary, factory_manager: FactoryManager, extra: float = 0.0, ) -> void:
	var next := _get_next_belt(factory_manager)
	if next != null and _conflicting_direction(next):
		item.progress = path.curve.get_baked_length()
		follow.progress = item.progress
		item.item.global_transform = follow.global_transform
		item["waiting"] = true
		return

	items_on_belt.erase(item)
	if next != null:
		_hand_off(item.item, next, extra)
	else:
		_drop_item(item.item, factory_manager)

func _detect_indexed_items(factory_manager: FactoryManager) -> void:
	if not block.block_data.is_placed or factory_manager == null:
		return

	for processable in factory_manager.get_processables_at(block.block_data.root_cell):
		var item := processable as FactoryItem
		if item != null and item.try_claim(self):
			add_item(item)

func _hand_off(	item: FactoryItem, next_belt: ConveyorBelt, overflow: float = 0.0,) -> void:
	if is_straight_corner(next_belt):
		overflow += 0.5
		var target_pos: Vector3 = next_belt.middle.global_position
		var tween = create_tween()
		tween.tween_property(item, "global_position", target_pos, 0.6)
		await tween.finished
	next_belt.add_item(item, overflow)

## Returns the conveyor occupying the forward cell, if one exists.
func _get_next_belt(factory_manager: FactoryManager) -> ConveyorBelt:
	if factory_manager == null:
		return null

	for machine in factory_manager.get_machines_at(_forward_cell()):
		var belt := machine as ConveyorBelt
		if belt != null and belt != self:
			return belt
	return null


func _same_direction(other: ConveyorBelt) -> bool:
	return other.block.block_data.block_rotation == block.block_data.block_rotation

func _conflicting_direction(other: ConveyorBelt) -> bool:
	return other._forward_direction() + self._forward_direction() == Vector3i.ZERO

func _forward_direction() -> Vector3i:
	const DIRECTIONS := {
		BlockData.Rotation.DEG0:   Vector3i(0, 0, -1),
		BlockData.Rotation.DEG90:  Vector3i(-1, 0, 0),
		BlockData.Rotation.DEG180: Vector3i(0, 0, 1),
		BlockData.Rotation.DEG270: Vector3i(1, 0, 0),
	}
	return DIRECTIONS[block.block_data.block_rotation]

func _drop_item(item: FactoryItem, factory_manager: FactoryManager) -> void:
	var drop_position := factory_manager.cell_to_world(_forward_cell())
	item.global_position = drop_position
	item.drop_at(drop_position)

func _forward_cell() -> Vector3i:
	return block.block_data.root_cell + _forward_direction()
