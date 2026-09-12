class_name RitualMachine
extends BasicMachine

@export var faith_restored := 10.0


func _on_recipe_completed(
	_completed_recipe: ProductionRecipe,
	factory_manager: FactoryManager,
) -> bool:
	FaithManager._apply_delta(faith_restored)

	var assembly := get_parent() as MachineAssembly
	if factory_manager != null:
		factory_manager.unregister_machine(self)
		if (
			factory_manager.grid != null
			and assembly != null
			and assembly.block != null
		):
			factory_manager.grid.remove_block(assembly.block)

	if assembly != null:
		assembly.queue_free()
	else:
		queue_free()

	# A ritual is single-use and must never claim another set of inputs.
	return false
