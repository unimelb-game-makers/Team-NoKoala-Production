class_name TelescopeMachine
extends BasicMachine

@export var recipes : Array[ProductionRecipe] = []

var repair_stage : int = 0

signal repair_completed

func _on_recipe_completed(
	_completed_recipe: ProductionRecipe,
	factory_manager: FactoryManager,
) -> bool:
	# TO DO: emit signal that repair is complete
	print("complete!")
	repair_completed.emit()
	repair_stage += 1
	#_change_recipe()
	
	# TO DO: change recipe

	# TO DO: fix this so telescope can be repaired multiple times
	return true
	
func _try_start_processing(factory_manager: FactoryManager) -> void:
	if definition == null or repair_stage >= recipes.size():
		return
	_try_start_recipe(recipes[repair_stage], factory_manager)
	if _processing_recipe != null:
		print("started: ", _processing_recipe.recipe_id,
			" workable: ", _check_workable(_processing_recipe))
		for req in _processing_recipe.work_requirements:
			print("  needs port=", req.port_id, " type=", req.work_type)
