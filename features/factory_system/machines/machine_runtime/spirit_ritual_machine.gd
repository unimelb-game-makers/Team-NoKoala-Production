class_name SpiritRitualMachine
extends BasicMachine

@export var faith_restored := 10.0


func _on_recipe_completed(
	_completed_recipe: ProductionRecipe,
	factory_manager: FactoryManager,
) -> bool:
	spirit_spawner.spawn_spirit(machine_assembly.global_position)
	if factory_manager != null:
		factory_manager.unregister_machine(self)
		if (
			factory_manager.grid != null
			and machine_assembly != null
			and machine_assembly.block != null
		):
			factory_manager.grid.remove_block(machine_assembly.block)

	machine_assembly.queue_free()

	# A ritual is single-use and must never claim another set of inputs.
	return false
