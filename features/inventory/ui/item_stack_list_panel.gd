class_name ItemStackListPanel
extends PanelContainer

## Lists the item stacks on the hovered cell and highlights the selected one.

const ICON_SIZE := Vector2(32.0, 32.0)
const SELECTED_COLOR := Color(1.0, 0.85, 0.4, 0.35)

@export var rows: VBoxContainer
@export var hint_label: Label

var _items: Array[FactoryItem] = []
var _quantities: Array[int] = []
var _selected_index := -1


func _ready() -> void:
	hint_label.text = "[%s] Next   [%s] Pick up" % [
		_action_text(&"next_item"),
		_action_text(&"pickup_item"),
	]
	hide()


func display(items: Array[FactoryItem], selected_index: int) -> void:
	if items.is_empty():
		_items.clear()
		_quantities.clear()
		hide()
		return

	var quantities: Array[int] = []
	for item in items:
		quantities.append(item.stack.quantity)
	if items != _items or quantities != _quantities or selected_index != _selected_index:
		_items = items.duplicate()
		_quantities = quantities
		_selected_index = selected_index
		_rebuild_rows()
	show()


func _rebuild_rows() -> void:
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	for i in _items.size():
		rows.add_child(_create_row(_items[i], i == _selected_index))


func _create_row(item: FactoryItem, is_selected: bool) -> Control:
	var row := PanelContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = SELECTED_COLOR if is_selected else Color.TRANSPARENT
	style.set_content_margin_all(4.0)
	style.set_corner_radius_all(4)
	row.add_theme_stylebox_override(&"panel", style)

	var content := HBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override(&"separation", 8)
	row.add_child(content)

	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = item.stack.item_definition.texture
	icon.custom_minimum_size = ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(icon)

	var label := Label.new()
	label.text = "%s x%d" % [item.stack.item_definition.item_name, item.stack.quantity]
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content.add_child(label)
	return row


func _action_text(action: StringName) -> String:
	var events := InputMap.action_get_events(action)
	if events.is_empty():
		return String(action)
	return events[0].as_text().trim_suffix(" (Physical)")
