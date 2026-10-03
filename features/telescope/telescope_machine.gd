class_name TelescopeMachine
extends BasicMachine


func _on_recipe_completed(
	_completed_recipe: ProductionRecipe,
	factory_manager: FactoryManager,
) -> bool:
	# TO DO: emit signal that repair is complete
	print("complete!")

	# TO DO: fix this so telescope can be repaired multiple times
	return true
