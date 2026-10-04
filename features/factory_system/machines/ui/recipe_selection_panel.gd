class_name RecipeSelectionPanel
extends MachineUIPanel

const CELL_SCENE := preload(
	"res://features/factory_system/machines/ui/recipe_grid_cell.tscn"
)

@export var recipe_panel: RecipePanel
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
	recipe_panel.display(
		_selected,
		machine.is_recipe_enabled(_selected) if _selected != null else false,
	)
