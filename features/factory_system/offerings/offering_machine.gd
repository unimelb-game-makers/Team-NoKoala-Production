class_name OfferingMachine
extends BasicMachine

signal stage_completed(stage_index: int, stage: OfferingStage)
signal all_stages_completed

@export var stages: Array[OfferingStage] = []

var current_stage_index := 0
var _warned_missing_unlocks := false


func _ready() -> void:
	_activate_current_stage()


func get_current_stage() -> OfferingStage:
	if current_stage_index < 0 or current_stage_index >= stages.size():
		return null
	return stages[current_stage_index]


func is_complete() -> bool:
	return current_stage_index >= stages.size()


func _factory_tick(delta: float, factory_manager: FactoryManager) -> void:
	var stage := get_current_stage()
	if stage != null and not stage.recipes_to_unlock.is_empty() and recipe_unlocks == null:
		if not _warned_missing_unlocks:
			push_warning("OfferingMachine needs RecipeUnlocks before processing a reward stage")
			_warned_missing_unlocks = true
		unregister_active()
		return
	super._factory_tick(delta, factory_manager)


func get_recipes(include_locked: bool = false) -> Array[ProductionRecipe]:
	var result: Array[ProductionRecipe] = []
	if include_locked:
		for stage in stages:
			if stage != null and stage.recipe != null:
				result.append(stage.recipe)
		return result
	var stage := get_current_stage()
	if stage != null and is_recipe_available(stage.recipe):
		result.append(stage.recipe)
	return result


func is_recipe_available(recipe: ProductionRecipe) -> bool:
	var stage := get_current_stage()
	return (
		stage != null
		and recipe != null
		and recipe == stage.recipe
		and definition != null
		and definition.is_recipe_valid(recipe)
		and _has_valid_rewards(stage)
	)


func can_process_recipe(recipe: ProductionRecipe) -> bool:
	var stage := get_current_stage()
	return (
		super.can_process_recipe(recipe)
		and stage != null
		and (stage.recipes_to_unlock.is_empty() or recipe_unlocks != null)
	)


func _on_recipe_completed(
	completed_recipe: ProductionRecipe,
	_factory_manager: FactoryManager,
) -> bool:
	var stage := get_current_stage()
	if stage == null or stage.recipe != completed_recipe:
		return false

	var completed_stage_index := current_stage_index
	current_stage_index += 1
	_activate_current_stage()

	for recipe in stage.recipes_to_unlock:
		if recipe != null and recipe_unlocks != null:
			recipe_unlocks.unlock_recipe(recipe)

	stage_completed.emit(completed_stage_index, stage)
	if is_complete():
		all_stages_completed.emit()
	# Start the next stage on a later factory tick.
	return false


func _activate_current_stage() -> void:
	var recipes: Array[ProductionRecipe] = []
	var stage := get_current_stage()
	if stage == null and not is_complete():
		push_error("Offering stage %d cannot be empty" % [current_stage_index + 1])
	elif stage != null:
		if stage.recipe == null:
			push_error("Offering stage %d needs a recipe" % [current_stage_index + 1])
		elif definition == null:
			push_error("OfferingMachine needs a machine definition")
		elif not definition.is_recipe_valid(stage.recipe):
			for error in definition.get_recipe_validation_errors(stage.recipe):
				push_error("Offering stage %d: %s" % [current_stage_index + 1, error])
		elif not _has_valid_rewards(stage):
			push_error(
				"Offering stage %d needs external recipe resources for all unlock rewards"
				% [current_stage_index + 1]
			)
		else:
			recipes.append(stage.recipe)
	set_enabled_recipes(recipes)
	available_recipes_changed.emit()
	_update_job_requests()


func _has_valid_rewards(stage: OfferingStage) -> bool:
	for recipe in stage.recipes_to_unlock:
		if recipe == null or recipe.resource_path.is_empty():
			return false
	return true
