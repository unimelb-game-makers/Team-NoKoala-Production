class_name JobBoard

static var _providers_by_type: Dictionary = {}


static func register(provider: JobProvider) -> void:
	if provider == null:
		return

	var job_type := provider.job_type()
	var providers: Array = _providers_by_type.get(job_type, [])
	if not providers.has(provider):
		providers.append(provider)
	_providers_by_type[job_type] = providers


static func unregister(provider: JobProvider) -> void:
	if provider == null:
		return

	var job_type := provider.job_type()
	var providers: Array = _providers_by_type.get(job_type, [])
	providers.erase(provider)
	if providers.is_empty():
		_providers_by_type.erase(job_type)
	else:
		_providers_by_type[job_type] = providers


static func get_providers(job_type: StringName) -> Array[JobProvider]:
	var result: Array[JobProvider] = []
	for provider: JobProvider in _providers_by_type.get(job_type, []):
		result.append(provider)
	return result


static func clear() -> void:
	_providers_by_type.clear()
