class_name Processable
extends Node

signal availability_changed(processable: Processable, is_available: bool)
signal claim_changed(processable: Processable, claimant: Object)
signal dropped(processable: Processable, world_position: Vector3)

# use to determine whether the resource is ready for process
# only ready when no claimant has claimed it and no set _available_for_processing to false
@export var available_for_processing: bool :
	get:
		return is_available_for_processing()
	set(value):
		set_available_for_processing(value)

# each processable is it's own stack
@export var stack: ItemStack

var _available_for_processing := false
var _claimant: Object
var _is_dropped := false
var _drop_world_position := Vector3.ZERO


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
	# TO DO: add something for visual merging (stack)
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

# --- stack management --- 
func can_merge_with(other: Processable) -> bool:
	return other != null and stack.can_merge_with(other.stack)

func merge_from(other: Processable) -> int:
	var leftover := stack.merge_from(other.stack)
	if leftover == 0:
		other.queue_free() # TO DO: fix this with proper deletion
	return leftover
	
func split(amount: int) -> Processable:
	# split it off into a new unclaimed processable
	if amount <= 0 or amount >= stack.quantity:
		return null
	var new_processable := duplicate() # TO DO: fix this, should be factory job I think
	new_processable.stack = stack.split(amount)
	new_processable.release_claim()
	return new_processable

# --- internal functions --- 

func is_available_for_processing() -> bool:
	_clear_invalid_claimant()
	return (
		_available_for_processing
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
