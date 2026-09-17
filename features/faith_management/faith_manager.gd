class_name FaithManager
extends Node

var registered_active: Dictionary[Machine, float] = {} # float = drain rate
var max_faith: float = 100.0
var current_faith: float = 100.0

signal faith_changed(current_faith, max_faith)

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


func register_drain(machine: Machine, drain_rate: float) -> void:
	assert(machine != null, "FaithManager cannot register a null machine")
	registered_active.set(machine, drain_rate)
	print(registered_active)


func unregister_drain(machine: Machine) -> void:
	registered_active.erase(machine)


func update_drain_rate(machine: Machine, drain_rate: float) -> void:
	if registered_active.has(machine):
		registered_active.set(machine, drain_rate)


func reset() -> void:
	registered_active.clear()
	current_faith = max_faith
	faith_changed.emit(current_faith, max_faith)
