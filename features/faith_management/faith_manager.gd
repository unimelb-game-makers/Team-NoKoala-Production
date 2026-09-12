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
		_apply_delta(-total_drain * delta)

func _apply_delta(amount: float) -> void:
	var old_faith := current_faith
	current_faith = clamp(current_faith + amount, 0.0, max_faith)
	if current_faith != old_faith:
		faith_changed.emit(current_faith, max_faith)

func _register_active(machine: Machine, drain_rate: float) -> void:
	registered_active.set(machine, drain_rate)

func _unregister_active(machine: Machine) -> void:
	registered_active.erase(machine)

func _update_drain_rate(machine: Machine, drain_rate: float) -> void:
	if registered_active.has(machine):
		registered_active.set(machine, drain_rate)
