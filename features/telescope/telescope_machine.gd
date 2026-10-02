class_name TelescopeMachine
extends BasicMachine

func _on_recipe_completed(
	_completed_recipe: ProductionRecipe,
	factory_manager: FactoryManager,
) -> bool:
	# TO DO: emit signal that repair is complete
	print("complete!")

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

	# TO DO: fix this so telescope can be repaired multiple times
	return false
