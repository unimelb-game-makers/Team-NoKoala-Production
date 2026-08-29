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
		_hand_off_to_neighbour(item.item)

func _hand_off_to_neighbour(item: FactoryItem) -> void:
	if neighbour:
		print("handing off, neighbour = ", neighbour, " self = ", self)
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

func _on_back_area_area_entered(area: Area3D) -> void:
	pass # Replace with function body.


func _on_forward_area_area_entered(area: Area3D) -> void:
	var other = area.get_parent() as ConveyorBelt
	if other == null or other == self:
		return
	set_neighbour(other)


func _on_left_area_area_entered(area: Area3D) -> void:
	pass # Replace with function body.


func _on_right_area_area_entered(area: Area3D) -> void:
	pass # Replace with function body.


func _on_forward_area_area_exited(area: Area3D) -> void:
	if not area.is_in_group("belt_edge"):
		return
	var other = area.get_parent() as ConveyorBelt
	if other == neighbour:
		set_neighbour(null)

func set_areas_enabled(enabled: bool) -> void:
	for area in [forward_area, back_area]:
		area.monitoring = enabled
		area.monitorable = enabled
