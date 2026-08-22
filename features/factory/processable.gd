class_name Processable
extends Node

signal availability_changed(processable: Processable, is_available: bool)
signal claim_changed(processable: Processable, claimant: Object)

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



# --- Claim processable when pickup or carried by any logistics ---

func try_claim(consumer: Object) -> bool:
	if consumer == null:
		return false

	_clear_invalid_claimant()
	if not is_available_for_processing():
		return false
	_claimant = consumer
	claim_changed.emit(self, _claimant)
	return true

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


# --- helper functions --- 

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
