class_name RecipeGridCell
extends Button

signal clicked(recipe: ProductionRecipe)

const DISABLED_MODULATE := Color(0.55, 0.55, 0.55, 1.0)

@export var selection: Control
@export var enabled_badge: Label

var recipe: ProductionRecipe


func _ready() -> void:
	pressed.connect(_on_pressed)


func display(p_recipe: ProductionRecipe, enabled: bool, selected: bool) -> void:
	recipe = p_recipe
	var product := _get_product(recipe)
	icon = product.texture if product != null else null
	text = "" if icon != null else recipe.display_name
	tooltip_text = recipe.display_name
	self_modulate = Color.WHITE if enabled else DISABLED_MODULATE
	enabled_badge.visible = enabled
	selection.visible = selected


func _get_product(p_recipe: ProductionRecipe) -> FactoryItemDefinition:
	for output in p_recipe.outputs:
		if output != null and output.item != null:
			return output.item
	return null


func _on_pressed() -> void:
	clicked.emit(recipe)
