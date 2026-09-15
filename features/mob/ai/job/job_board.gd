class_name JobBoard

static var _providers: Array[JobProvider] = []


static func register(provider: JobProvider) -> void:
	if provider == null:
		return

	if not _providers.has(provider):
		_providers.append(provider)


static func unregister(provider: JobProvider) -> void:
	if provider == null:
		return

	_providers.erase(provider)


static func get_providers() -> Array[JobProvider]:
	return _providers.duplicate()


static func clear() -> void:
	_providers.clear()
