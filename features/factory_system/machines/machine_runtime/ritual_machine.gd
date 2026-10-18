class_name RitualMachine
extends BasicMachine

@export var faith_restored := 10.0


func _on_recipe_completed(
	_completed_recipe: ProductionRecipe,
	_factory_manager: FactoryManager,
) -> bool:
	faith_manager.apply_delta(faith_restored)

	if machine_assembly != null:
		machine_assembly.remove_from_world()
	else:
		queue_free()

	# A ritual is single-use and must never claim another set of inputs.
	return false
