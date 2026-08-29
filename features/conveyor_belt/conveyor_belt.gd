class_name ConveyorBelt
extends Block

@export var speed: float = 2.0
@onready var path: Path3D = $Path3D
@onready var follow: PathFollow3D = $Path3D/PathFollow3D
@onready var exit_area: Area3D = $ExitArea

var items_on_belt: Array[Dictionary] = []

func add_item(item: Node3D) -> void:
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
		_hand_off_to_next_segment(item.item)

func _hand_off_to_next_segment(item: Node3D) -> void:
	var overlapping := exit_area.get_overlapping_areas()
	for area in overlapping:
		var next_segment = area.get_parent()
		if next_segment is ConveyorBelt:
			next_segment.add_item(item)
			return
