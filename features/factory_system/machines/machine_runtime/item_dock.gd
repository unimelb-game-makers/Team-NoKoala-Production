class_name ItemDock
extends Machine

@export var hide_inputs_while_processing := true

const DEFAULT_SPAWN_HEIGHT: float = 0.167

var _factory_manager: FactoryManager

func _factory_tick(delta: float, factory_manager: FactoryManager) -> void:

	if factory_manager == null:
		return

	_factory_manager = factory_manager
	_update_job_requests()

func has_allowed_item(item: FactoryItemDefinition) -> bool:
	if item in allowed_items: return true
	return false
