class_name ProductionRecipe
extends Resource

@export var recipe_id: StringName
@export var display_name: String
@export var duration_seconds := 1.0
@export var inputs: Array[RecipeItemAmount] = []
@export var outputs: Array[RecipeItemAmount] = []
