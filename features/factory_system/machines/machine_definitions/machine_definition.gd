class_name MachineDefinition
extends Resource


@export var cells: Array[MachineCellDefinition] = []

@export var recipes: Array[ProductionRecipe] = []

func _get_ports_for_role(
	role: MachineCellDefinition.Role,
) -> Dictionary[StringName, bool]:
	var result: Dictionary[StringName, bool] = {}
	for cell in cells:
		if cell != null and cell.role == role and not cell.port_id.is_empty():
			result[cell.port_id] = true
	return result


func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var recipe_ids: Dictionary[StringName, bool] = {}

	for index in cells.size():
		var cell := cells[index]
		if cell == null:
			errors.append("Machine cell %d cannot be empty." % index)
			continue
		if (
			cell.role != MachineCellDefinition.Role.STRUCTURE
			and cell.port_id.is_empty()
		):
			errors.append("Machine cell %d must specify a port ID." % index)

	for index in recipes.size():
		var recipe := recipes[index]
		if recipe == null:
			errors.append("Recipe entry %d cannot be empty." % index)
			continue

		if not recipe.recipe_id.is_empty():
			if recipe_ids.has(recipe.recipe_id):
				errors.append(
					"Recipe entry %d duplicates recipe ID '%s'." % [
						index,
						recipe.recipe_id,
					]
				)
			else:
				recipe_ids[recipe.recipe_id] = true

		for recipe_error in get_recipe_validation_errors(recipe):
			errors.append("Recipe entry %d: %s" % [index, recipe_error])

	return errors


func get_recipe_validation_errors(
	recipe: ProductionRecipe,
) -> PackedStringArray:
	var errors := PackedStringArray()
	if recipe == null:
		errors.append("Recipe cannot be empty.")
		return errors

	if recipe.recipe_id.is_empty():
		errors.append("Recipe ID cannot be empty.")
	if recipe.duration_seconds <= 0.0:
		errors.append("Recipe duration must be greater than zero.")
	if recipe.outputs.is_empty():
		errors.append("Recipe must contain at least one output.")

	errors.append_array(
		_get_recipe_entry_errors(
			recipe.inputs,
			"input",
			MachineCellDefinition.Role.INPUT,
		)
	)
	errors.append_array(
		_get_recipe_entry_errors(
			recipe.outputs,
			"output",
			MachineCellDefinition.Role.OUTPUT,
		)
	)

	return errors


func is_recipe_valid(recipe: ProductionRecipe) -> bool:
	return get_recipe_validation_errors(recipe).is_empty()


func _get_recipe_entry_errors(
	entries: Array[RecipeItemAmount],
	entry_type: String,
	port_role: MachineCellDefinition.Role,
) -> PackedStringArray:
	var errors := PackedStringArray()
	var available_ports := _get_ports_for_role(port_role)
	var seen_entries: Dictionary[String, bool] = {}

	for index in entries.size():
		var entry := entries[index]
		var label := "%s entry %d" % [entry_type.capitalize(), index]

		if entry == null:
			errors.append("%s cannot be empty." % label)
			continue
		if entry.port_id.is_empty():
			errors.append("%s must specify a port ID." % label)
		elif not available_ports.has(entry.port_id):
			errors.append(
				"%s references unknown port '%s'." % [label, entry.port_id]
			)
		if entry.item == null:
			errors.append("%s must specify an item." % label)
			continue
		if entry.amount <= 0:
			errors.append("%s amount must be greater than zero." % label)

		var entry_key := "%s:%d" % [entry.port_id, entry.item.get_instance_id()]
		if seen_entries.has(entry_key):
			errors.append(
				"%s duplicates item '%s' on port '%s'." % [
					label,
					entry.item.item_name,
					entry.port_id,
				]
			)
		else:
			seen_entries[entry_key] = true

	return errors
