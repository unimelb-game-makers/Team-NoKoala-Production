class_name ItemSelectionPanel
extends MachineUIPanel

const CELL_SCENE := preload(
	"res://features/factory_system/machines/ui/item_grid_cell.tscn"
)
const ITEM_ICON_SIZE := Vector2(24, 24)

@export var grid: GridContainer

var _cells: Array[ItemGridCell] = []


func _on_open() -> void:
	machine.enabled_recipes_changed.connect(_refresh)
	_build_grid()
	_refresh()


func _on_close() -> void:
	if (
		is_instance_valid(machine)
		and machine.enabled_recipes_changed.is_connected(_refresh)
	):
		machine.enabled_recipes_changed.disconnect(_refresh)
	_clear_grid()


func _build_grid() -> void:
	_clear_grid()
	if machine.definition == null:
		return
	for item in FactoryItemDefinition.factory_item_definitions.values():
		if item == null:
			continue
		var cell := CELL_SCENE.instantiate() as ItemGridCell
		grid.add_child(cell)
		cell.clicked.connect(_on_cell_clicked)
		cell.item_def = load(item)
		_cells.append(cell)


func _clear_grid() -> void:
	for cell in _cells:
		grid.remove_child(cell)
		cell.queue_free()
	_cells.clear()


func _on_cell_clicked(item: FactoryItemDefinition) -> void:
	if machine == null:
		return
	
	if machine.has_allowed_item(item):
		machine.allowed_items.erase(item)
	else:
		machine.allowed_items.append(item)
	_refresh()


func _refresh() -> void:
	if machine == null:
		return
	for cell in _cells:
		cell.display(
			cell.item_def,
			machine.has_allowed_item(cell.item_def),
			false
		)

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
