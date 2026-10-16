class_name FactoryItem
extends Processable

## Emitted when a flight started by [method fall_from] or [method launch]
## reaches the floor.
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
## Height of the floor the current flight ends on.
var _flight_floor := 0.0
## Exact landing spot for [method fall_from]; launched items land wherever they
## hit the floor.
var _flight_target := Vector3.ZERO
var _has_flight_target := false
## How long an item takes to slide into its cell when it has no height to fall.
const SNAP_SLIDE_DURATION := 0.12
const BASE_SIZE := Vector2(32.0, 32.0)

var _snap_tween: Tween

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
	if _flight_velocity.y < 0.0 and next_position.y <= _flight_floor:
		next_position.y = _flight_floor
		global_position = _flight_target if _has_flight_target else next_position
		_in_flight = false
		landed.emit(self)
	else:
		global_position = next_position


## Visually moves the item from `start_position` onto its current
## (already grid-snapped) position: it falls there if `start_position` is
## above it, otherwise it slides.
func fall_from(start_position: Vector3) -> void:
	_kill_snap_tween()
	_flight_target = global_position
	if start_position.y <= _flight_target.y:
		_slide_from(start_position)
		return
	_flight_floor = _flight_target.y
	_has_flight_target = true
	global_position = start_position
	# Drift sideways during the fall so it arrives at the target on landing
	# instead of jumping there.
	var fall_time := sqrt(2.0 * (start_position.y - _flight_target.y) / _get_gravity())
	_flight_velocity = Vector3.ZERO
	if fall_time > 0.0:
		var offset := _flight_target - start_position
		_flight_velocity = Vector3(offset.x, 0.0, offset.z) / fall_time
	_in_flight = true


func _slide_from(start_position: Vector3) -> void:
	var target := global_position
	if start_position.is_equal_approx(target):
		return
	global_position = start_position
	_snap_tween = create_tween()
	_snap_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_snap_tween.tween_property(self, "global_position", target, SNAP_SLIDE_DURATION)


func _kill_snap_tween() -> void:
	if _snap_tween != null and _snap_tween.is_valid():
		_snap_tween.kill()
	_snap_tween = null


## Throws the item from its current position with `velocity`; it flies under
## gravity until it comes down to `floor_height`.
func launch(velocity: Vector3, floor_height: float) -> void:
	_kill_snap_tween()
	_flight_velocity = velocity
	_flight_floor = floor_height
	_has_flight_target = false
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
