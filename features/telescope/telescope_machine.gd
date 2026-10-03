class_name TelescopeMachine
extends BasicMachine

@export var recipes : Array[ProductionRecipe] = []

var repair_stage : int = 0
var waiting_for_discovery : bool = false

signal repair_completed

func _on_recipe_completed(
	_completed_recipe: ProductionRecipe,
	factory_manager: FactoryManager,
) -> bool:
	
	repair_stage += 1
	waiting_for_discovery = true
	repair_completed.emit()

	return true

func resume() -> void:
	waiting_for_discovery = false
	
func _try_start_processing(factory_manager: FactoryManager) -> void:
	if waiting_for_discovery or definition == null or repair_stage >= recipes.size():
		return
	var recipe := recipes[repair_stage]
	_try_start_recipe(recipe, factory_manager)
