class_name JobBoard
extends Node

var _providers: Array[JobProvider] = []


func register(provider: JobProvider) -> void:
	if provider == null:
		return

	if not _providers.has(provider):
		_providers.append(provider)


func unregister(provider: JobProvider) -> void:
	if provider == null:
		return

	_providers.erase(provider)


func get_providers() -> Array[JobProvider]:
	return _providers.duplicate()


func clear() -> void:
	for provider in _providers.duplicate():
		if is_instance_valid(provider):
			provider.deactivate()
	_providers.clear()
