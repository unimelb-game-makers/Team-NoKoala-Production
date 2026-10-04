class_name RecipePanel
extends VBoxContainer

const ITEM_ICON_SIZE := Vector2(24, 24)

@export var name_label: Label
@export var duration_label: Label
@export var inputs_group: HBoxContainer
@export var inputs_row: HBoxContainer
@export var outputs_group: HBoxContainer
@export var outputs_row: HBoxContainer
@export var work_label: Label
@export var status_label: Label


func display(
	recipe: ProductionRecipe,
	enabled: bool,
	show_enabled_status: bool = true,
) -> void:
	var has_recipe := recipe != null
	for label in [duration_label, work_label]:
		label.visible = has_recipe
	status_label.visible = has_recipe and show_enabled_status
	inputs_group.visible = has_recipe
	outputs_group.visible = has_recipe
	if not has_recipe:
		name_label.text = "No recipes"
		_clear_item_row(inputs_row)
		_clear_item_row(outputs_row)
		return

	name_label.text = recipe.display_name.capitalize()
	duration_label.text = "Duration: %.1fs" % recipe.duration_seconds
	_fill_item_row(inputs_row, recipe.inputs)
	_fill_item_row(outputs_row, recipe.outputs)

	var work_entries := PackedStringArray()
	for requirement in recipe.work_requirements:
		if requirement == null:
			continue
		work_entries.append(
			String(WorkType.Value.keys()[requirement.work_type]).capitalize()
		)
	work_label.text = "Work: %s" % (
		", ".join(work_entries) if not work_entries.is_empty() else "None"
	)

	status_label.text = "%s (click again to %s)" % [
		"Enabled" if enabled else "Disabled",
		"disable" if enabled else "enable",
	]
	status_label.modulate = Color(0.45, 1, 0.45) if enabled else Color(1, 0.5, 0.5)


func _fill_item_row(row: HBoxContainer, entries: Array[RecipeItemAmount]) -> void:
	_clear_item_row(row)
	for entry in entries:
		if entry == null or entry.item == null:
			continue
		var icon := TextureRect.new()
		icon.texture = entry.item.texture
		icon.custom_minimum_size = ITEM_ICON_SIZE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		var label := Label.new()
		label.text = "%s x%d" % [entry.item.item_name, entry.amount]
		row.add_child(label)
	if row.get_child_count() == 0:
		var none := Label.new()
		none.text = "None"
		row.add_child(none)


func _clear_item_row(row: HBoxContainer) -> void:
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()
