class_name FaithManager
extends Node

var registered_active: Dictionary[Machine, float] = {} # float = drain rate
var max_faith: float = 100.0
var current_faith: float = 100.0
var is_empty: bool = false
var recovery_threshold: float = 10.0

signal faith_changed(current_faith, max_faith)
signal faith_depleted
signal faith_restored

func _process(delta: float) -> void:
	if registered_active.is_empty():
		return

	var total_drain: float = 0.0
	for rate in registered_active.values():
		total_drain += rate
	if total_drain != 0.0:
		apply_delta(-total_drain * delta)


func apply_delta(amount: float) -> void:
	var old_faith := current_faith
	current_faith = clamp(current_faith + amount, 0.0, max_faith)
	if current_faith != old_faith:
		faith_changed.emit(current_faith, max_faith)
	_check_empty()
		
func try_drain() -> bool:
	return !_check_empty()

func register_drain(machine: Machine, drain_rate: float) -> void:
	assert(machine != null, "FaithManager cannot register a null machine")
	registered_active.set(machine, drain_rate)


func unregister_drain(machine: Machine) -> void:
	registered_active.erase(machine)


func update_drain_rate(machine: Machine, drain_rate: float) -> void:
	if registered_active.has(machine):
		registered_active.set(machine, drain_rate)


func reset() -> void:
	registered_active.clear()
	current_faith = max_faith
	faith_changed.emit(current_faith, max_faith)

func _check_empty() -> bool:
	if current_faith <= 0.0 and not is_empty:
		is_empty = true
		faith_depleted.emit()
		print("empty")
		return true
		# when this happens, factory manager needs to:
		# - shut down all active machines
		# - this means working at a machine will do nothing
		# - workers should not look for work at shut down machines
		# - i.e pause progress bars
	elif is_empty and current_faith >= recovery_threshold:
		is_empty = false
		faith_restored.emit()
		print("restored")
		return false
		# when this happens factory manager needs to:
		# - reactivate the deactivated machines
		# - this means they are reopen for work
		# - progress bars continue how they were
	
	return is_empty

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
			apply_delta(10.0)
