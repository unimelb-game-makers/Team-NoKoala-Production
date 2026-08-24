class_name Processable
extends Node

signal availability_changed(processable: Processable, is_available: bool)
signal claim_changed(processable: Processable, claimant: Object)
signal dropped(processable: Processable, world_position: Vector3)

@export var definition: ProcessableDefinition

# use to determine whether the resource is ready for process
# only ready when no claimant has claimed it and no set _available_for_processing to false
@export var available_for_processing: bool :
	get:
		return is_available_for_processing()
	set(value):
		set_available_for_processing(value)

var _available_for_processing := false
var _claimant: Object
var _is_dropped := false
var _drop_world_position := Vector3.ZERO
@onready var sprite: Sprite3D = $Sprite3D

func _ready() -> void:
	sprite.texture = definition.texture

# --- Claim processable when pickup or carried by any logistics ---

func try_claim(consumer: Object) -> bool:
	if consumer == null:
		return false

	_clear_invalid_claimant()
	if not is_available_for_processing():
		return false
	_is_dropped = false
	_claimant = consumer
	claim_changed.emit(self, _claimant)
	return true



func drop_at(world_position: Vector3) -> void:
	release_claim()
	_is_dropped = true
	_drop_world_position = world_position
	set_available_for_processing(true)
	dropped.emit(self, world_position)

func is_dropped() -> bool:
	return _is_dropped

func get_drop_world_position() -> Vector3:
	return _drop_world_position


func release_claim() -> bool:
	_clear_invalid_claimant()

	_claimant = null
	claim_changed.emit(self, null)
	return true

func is_claimed() -> bool:
	_clear_invalid_claimant()
	return _claimant != null

func get_claimant() -> Object:
	_clear_invalid_claimant()
	return _claimant


# --- internal functions --- 

func is_available_for_processing() -> bool:
	_clear_invalid_claimant()
	return (
		_available_for_processing
		and definition != null
		and _claimant == null
	)

func set_available_for_processing(value: bool) -> void:
	if _available_for_processing == value:
		return

	_available_for_processing = value
	availability_changed.emit(self, value)

func _clear_invalid_claimant() -> void:
	if _claimant != null and not is_instance_valid(_claimant):
		_claimant = null
		claim_changed.emit(self, null)


func _on_area_3d_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if Player.player_instance.global_position.distance_to(self.global_position) > Player.PICKUP_DISTANCE: return
			if Player.player_instance.item_manager.held_processable != null: return
			
			try_claim(Player.player_instance)
			Player.player_instance.item_manager.held_processable = self
