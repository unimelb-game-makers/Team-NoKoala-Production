class_name FactoryItem
extends Processable

@onready var sprite: Sprite3D = $Sprite3D
@onready var pickup_area: Area3D = $Sprite3D/Area3D
@onready var debug_label: Label3D = $Sprite3D/StackDebugLabel

var factory_manager: FactoryManager

var _pickup_collision_layer: int
var _pickup_input_ray_pickable: bool
var _pickup_enabled := true
var _in_process_hidden := false
const BASE_SIZE := Vector2(32.0, 32.0)

func _ready() -> void:
	if stack == null:
		return
	sprite.texture = stack.item_definition.texture
	var texture_size := sprite.texture.get_size()
	var scale_factor := 32.0 / maxf(sprite.texture.get_width(), sprite.texture.get_height())
	sprite.scale = 2* Vector3.ONE * scale_factor
	_pickup_collision_layer = pickup_area.collision_layer
	
	_pickup_input_ray_pickable = pickup_area.input_ray_pickable
	

func _process(_delta: float) -> void:
	if debug_label.visible and stack != null:
		if stack.quantity > 1:
			debug_label.text = str(stack.quantity)
		else:
			debug_label.text = ""

func set_in_process_hidden(is_hidden: bool) -> void:
	_in_process_hidden = is_hidden
	sprite.visible = not is_hidden
	_update_pickup_interaction()


func set_pickup_enabled(enabled: bool) -> void:
	_pickup_enabled = enabled
	if is_node_ready():
		_update_pickup_interaction()


func can_pick_up() -> bool:
	return _pickup_enabled and not _in_process_hidden


func _update_pickup_interaction() -> void:
	var interactive := can_pick_up()
	pickup_area.collision_layer = _pickup_collision_layer if interactive else 0
	pickup_area.input_ray_pickable = (
		_pickup_input_ray_pickable if interactive else false
	)

func try_drop(coordinate: Vector3) -> bool:
	if factory_manager == null or factory_manager.grid == null:
		return false
	if stack == null or stack.is_empty():
		return false

	var cell := factory_manager.grid.world_to_cell(coordinate)
	return factory_manager.try_merge_item_at_cell(self, cell)
