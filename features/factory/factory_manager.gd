extends Node

var _factories: Array[FactoryMachine] = []
var _processables: Array[Processable] = []

func register_factory(factory: FactoryMachine) -> bool:
	if _factories.has(factory):
		return false

	_factories.append(factory)
	return true

func unregister_factory(factory: FactoryMachine) -> bool:
	var index := _factories.find(factory)
	if index == -1:
		return false

	_factories.remove_at(index)
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

func get_factories() -> Array[FactoryMachine]:
	return _factories.duplicate()

func get_processables() -> Array[Processable]:
	return _processables.duplicate()
