class_name TelescopeMachine
extends BasicMachine

signal repair_completed

func _on_recipe_completed(
	_completed_recipe: ProductionRecipe,
	factory_manager: FactoryManager,
) -> bool:
	# TO DO: emit signal that repair is complete
	print("complete!")
	repair_completed.emit()
	
	# TO DO: change recipe

	# TO DO: fix this so telescope can be repaired multiple times
	return true
