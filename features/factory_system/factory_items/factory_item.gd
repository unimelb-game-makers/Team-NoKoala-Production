class_name FactoryItem
extends Processable

## Emitted when a flight started by [method fall_from] or [method launch_to]
## reaches its target.
signal landed(item: FactoryItem)

@onready var sprite: Sprite3D = $Sprite3D
@export var pickup_area: Area3D
@onready var debug_label: Label3D = $StackDebugLabel

var factory_manager: FactoryManager

var _pickup_collision_layer: int
var _pickup_input_ray_pickable: bool
var _pickup_enabled := true
var _in_process_hidden := false
var _in_flight := false
var _flight_velocity := Vector3.ZERO
var _flight_target := Vector3.ZERO
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
	# Not a child of the sprite, so follow its visibility (hidden slots, items
	# inside machines) by hand.
	debug_label.visible = sprite.visible and stack != null and stack.quantity > 1
	if debug_label.visible:
		debug_label.text = str(stack.quantity)

func _physics_process(delta: float) -> void:
	if not _in_flight:
		return
	# Someone grabbed it mid-air; whoever holds it now owns its position.
	if is_claimed():
		_in_flight = false
		return

	_flight_velocity.y -= _get_gravity() * delta
	var next_position := global_position + _flight_velocity * delta
	if _flight_velocity.y < 0.0 and next_position.y <= _flight_target.y:
		global_position = _flight_target
		_in_flight = false
		landed.emit(self)
	else:
		global_position = next_position


## Visually drops the item from `start_position` down onto its current
## (already grid-snapped) position, snapping to the cell when it lands.
func fall_from(start_position: Vector3) -> void:
	_flight_target = global_position
	if start_position.y <= _flight_target.y:
		return
	global_position = start_position
	_flight_velocity = Vector3.ZERO
	_in_flight = true


## Throws the item from its current position so that it lands exactly on
## `target` after `flight_time` seconds.
func launch_to(target: Vector3, flight_time: float) -> void:
	var offset := target - global_position
	_flight_velocity = Vector3(
		offset.x / flight_time,
		(offset.y + 0.5 * _get_gravity() * flight_time * flight_time) / flight_time,
		offset.z / flight_time,
	)
	_flight_target = target
	_in_flight = true


func _get_gravity() -> float:
	return ProjectSettings.get_setting("physics/3d/default_gravity")


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
