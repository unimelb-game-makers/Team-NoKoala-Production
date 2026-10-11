class_name OfferingStage
extends Resource

## The recipe the offering machine processes during this stage.
@export var recipe: ProductionRecipe

## Player-selectable production recipes granted when the offering completes.
@export var recipes_to_unlock: Array[ProductionRecipe] = []
