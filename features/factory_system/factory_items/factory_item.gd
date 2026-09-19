class_name FactoryItem
extends Processable

@onready var sprite: Sprite3D = $Sprite3D
@onready var pickup_area: Area3D = $Sprite3D/Area3D
@onready var debug_label: Label3D = $Sprite3D/StackDebugLabel

var factory_manager: FactoryManager

var _pickup_collision_layer: int
var _pickup_input_ray_pickable: bool

func _ready() -> void:
	if stack == null:
		return
	sprite.texture = stack.item_definition.texture
	_pickup_collision_layer = pickup_area.collision_layer
	_pickup_input_ray_pickable = pickup_area.input_ray_pickable

func _process(_delta: float) -> void:
	if debug_label.visible and stack != null and stack.quantity > 1:
		debug_label.text = str(stack.quantity)

func set_in_process_hidden(is_hidden: bool) -> void:
	sprite.visible = not is_hidden
	pickup_area.collision_layer = 0 if is_hidden else _pickup_collision_layer
	pickup_area.input_ray_pickable = (
		false if is_hidden else _pickup_input_ray_pickable
	)

func try_drop(coordinate: Vector3) -> bool:
	if factory_manager == null or factory_manager.grid == null:
		return false
	if stack == null or stack.is_empty():
		return false

	var cell := factory_manager.grid.world_to_cell(coordinate)
	return factory_manager.try_merge_item_at_cell(self, cell)
