class_name SpiritRitualMachine
extends BasicMachine

@export var faith_restored := 10.0


func _on_recipe_completed(
	_completed_recipe: ProductionRecipe,
	_factory_manager: FactoryManager,
) -> bool:
	spirit_spawner.spawn_spirit(machine_assembly.global_position)
	machine_assembly.remove_from_world()

	# A ritual is single-use and must never claim another set of inputs.
	return false
