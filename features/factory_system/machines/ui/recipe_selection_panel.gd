class_name RecipeSelectionPanel
extends MachineUIPanel

const CELL_SCENE := preload(
	"res://features/factory_system/machines/ui/recipe_grid_cell.tscn"
)
const ITEM_ICON_SIZE := Vector2(24, 24)

@export var name_label: Label
@export var duration_label: Label
@export var inputs_row: HBoxContainer
@export var outputs_row: HBoxContainer
@export var work_label: Label
@export var status_label: Label
@export var grid: GridContainer

var _selected: ProductionRecipe
var _cells: Array[RecipeGridCell] = []


func _on_open() -> void:
	machine.enabled_recipes_changed.connect(_refresh)
	_build_grid()
	_selected = _cells[0].recipe if not _cells.is_empty() else null
	_refresh()


func _on_close() -> void:
	if (
		is_instance_valid(machine)
		and machine.enabled_recipes_changed.is_connected(_refresh)
	):
		machine.enabled_recipes_changed.disconnect(_refresh)
	_selected = null
	_clear_grid()


func _build_grid() -> void:
	_clear_grid()
	if machine.definition == null:
		return
	for recipe in machine.definition.recipes:
		if recipe == null:
			continue
		var cell := CELL_SCENE.instantiate() as RecipeGridCell
		grid.add_child(cell)
		cell.clicked.connect(_on_cell_clicked)
		cell.recipe = recipe
		_cells.append(cell)


func _clear_grid() -> void:
	for cell in _cells:
		grid.remove_child(cell)
		cell.queue_free()
	_cells.clear()


func _on_cell_clicked(recipe: ProductionRecipe) -> void:
	if machine == null:
		return
	if recipe != _selected:
		_selected = recipe
		_refresh()
		return
	if machine.is_recipe_enabled(recipe):
		machine.disable_recipe(recipe)
	else:
		machine.enable_recipe(recipe)


func _refresh() -> void:
	if machine == null:
		return
	for cell in _cells:
		cell.display(
			cell.recipe,
			machine.is_recipe_enabled(cell.recipe),
			cell.recipe == _selected,
		)
	_refresh_detail()


func _refresh_detail() -> void:
	var has_recipe := _selected != null
	for label in [duration_label, work_label, status_label]:
		label.visible = has_recipe
	inputs_row.get_parent().visible = has_recipe
	outputs_row.get_parent().visible = has_recipe
	if not has_recipe:
		name_label.text = "No recipes"
		return

	name_label.text = _selected.display_name.capitalize()
	duration_label.text = "Duration: %.1fs" % _selected.duration_seconds
	_fill_item_row(inputs_row, _selected.inputs)
	_fill_item_row(outputs_row, _selected.outputs)

	var work_entries := PackedStringArray()
	for requirement in _selected.work_requirements:
		if requirement == null:
			continue
		work_entries.append(
			String(WorkType.Value.keys()[requirement.work_type]).capitalize()
		)
	work_label.text = "Work: %s" % (
		", ".join(work_entries) if not work_entries.is_empty() else "None"
	)

	var enabled := machine.is_recipe_enabled(_selected)
	status_label.text = "%s (click again to %s)" % [
		"Enabled" if enabled else "Disabled",
		"disable" if enabled else "enable",
	]
	status_label.modulate = Color(0.45, 1, 0.45) if enabled else Color(1, 0.5, 0.5)


func _fill_item_row(row: HBoxContainer, entries: Array[RecipeItemAmount]) -> void:
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()
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
