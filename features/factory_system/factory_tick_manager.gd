class_name FactoryTickManager
extends Node

@export var factory_manager: FactoryManager

var tick_count := 0

func tick_all(delta: float) -> void:
	tick_count += 1
	var machines := factory_manager.get_machines()
	for machine in machines:
		if (
			not is_instance_valid(machine)
			or machine.is_queued_for_deletion()
			or not factory_manager.is_machine_registered(machine)
		):
			continue
		machine.factory_tick(delta, factory_manager)

func reset_tick_count() -> void:
	tick_count = 0
