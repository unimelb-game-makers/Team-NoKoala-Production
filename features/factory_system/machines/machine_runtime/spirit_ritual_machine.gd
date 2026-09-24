class_name SpiritRitualMachine
extends BasicMachine

@export var faith_restored := 10.0


func _on_recipe_completed(
	_completed_recipe: ProductionRecipe,
	factory_manager: FactoryManager,
) -> bool:
	var world := get_tree().get_first_node_in_group("world")
	var context := world.context as WorldContext
	var spirit := SpiritFactory.create_spirit(context)
	mobs_root.add_child(spirit)

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
