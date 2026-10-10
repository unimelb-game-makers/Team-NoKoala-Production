class_name RecipeUnlocks
extends Node

signal recipe_unlocked(recipe: ProductionRecipe)

## Recipes available when this world starts. Other production recipes must be
## granted with unlock_recipe before any machine can use them.
@export var initially_unlocked: Array[ProductionRecipe] = []

var _unlocked_paths: Dictionary[String, bool] = {}


func is_unlocked(recipe: ProductionRecipe) -> bool:
	var path := _recipe_path(recipe)
	if path.is_empty():
		return false
	if _unlocked_paths.has(path):
		return true
	for initial_recipe in initially_unlocked:
		if _recipe_path(initial_recipe) == path:
			return true
	return false


func unlock_recipe(recipe: ProductionRecipe) -> bool:
	var path := _recipe_path(recipe)
	if path.is_empty() or is_unlocked(recipe):
		return false
	_unlocked_paths[path] = true
	recipe_unlocked.emit(recipe)
	return true


func _recipe_path(recipe: ProductionRecipe) -> String:
	return recipe.resource_path if recipe != null else ""
