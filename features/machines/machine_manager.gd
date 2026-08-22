class_name MachineManager
extends Node


@export var grid: Grid
var _machines: Array[Machine] = []
var _processables: Array[Processable] = []

func register_machine(machine: Machine) -> bool:
	if _machines.has(machine):
		return false

	_machines.append(machine)
	return true

func unregister_machine(machine: Machine) -> bool:
	var index := _machines.find(machine)
	if index == -1:
		return false

	_machines.remove_at(index)
	return true

func register_processable(processable: Processable) -> bool:
	if processable == null or _processables.has(processable):
		return false

	_processables.append(processable)
	return true

func unregister_processable(processable: Processable) -> bool:
	var index := _processables.find(processable)
	if index == -1:
		return false

	_processables.remove_at(index)
	return true

func get_machines() -> Array[Machine]:
	return _machines.duplicate()

func get_processables() -> Array[Processable]:
	return _processables.duplicate()
