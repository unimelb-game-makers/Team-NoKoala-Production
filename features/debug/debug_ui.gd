class_name DebugUI
extends CanvasLayer

const ITEM_DEFINITIONS_DIR := "res://features/factory_system/factory_items/item_definitions"

@export var toggle_button: Button
@export var panel: PanelContainer
@export var close_button: Button
@export var faith_value_label: Label
@export var faith_spinbox: SpinBox
@export var set_faith_button: Button
@export var item_list: ItemList
@export var spawn_item_button: Button

var _context: WorldContext
var _item_definitions: Array[FactoryItemDefinition] = []
var _overlay_hidden := false


func _ready() -> void:
	toggle_button.pressed.connect(toggle)
	close_button.pressed.connect(close)
	set_faith_button.pressed.connect(_on_set_faith_pressed)
	faith_spinbox.get_line_edit().text_submitted.connect(_on_faith_submitted)
	spawn_item_button.pressed.connect(_on_spawn_item_pressed)
	item_list.item_activated.connect(_on_item_activated)
	item_list.item_selected.connect(_on_item_selected)
	panel.gui_input.connect(_on_debug_area_gui_input)
	_load_item_definitions()
	panel.hide()
	_update_controls()


func bind_world(context: WorldContext) -> void:
	if _context == context:
		return
	unbind_world()
	_context = context
	if _context != null and _context.faith != null:
		_context.faith.faith_changed.connect(_on_faith_changed)
		_sync_faith_ui(_context.faith.current_faith, _context.faith.max_faith)
	_update_controls()


func unbind_world() -> void:
	if (
		_context != null
		and is_instance_valid(_context.faith)
		and _context.faith.faith_changed.is_connected(_on_faith_changed)
	):
		_context.faith.faith_changed.disconnect(_on_faith_changed)
	_context = null
	close()
	_update_controls()


func set_overlay_hidden(hidden: bool) -> void:
	_overlay_hidden = hidden
	visible = not hidden


func toggle() -> void:
	if panel.visible:
		close()
	else:
		open()


func open() -> void:
	if _context != null and _context.faith != null:
		_sync_faith_ui(_context.faith.current_faith, _context.faith.max_faith)
	panel.show()


func close() -> void:
	panel.hide()


func _unhandled_input(event: InputEvent) -> void:
	if _overlay_hidden or _context == null:
		return
	if event.is_action_pressed("toggle_debug"):
		toggle()
		get_viewport().set_input_as_handled()
	elif panel.visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _load_item_definitions() -> void:
	_item_definitions.clear()
	item_list.clear()

	for file_name in ResourceLoader.list_directory(ITEM_DEFINITIONS_DIR):
		if not file_name.ends_with(".tres"):
			continue
		var path := "%s/%s" % [ITEM_DEFINITIONS_DIR, file_name]
		var definition := load(path) as FactoryItemDefinition
		if definition != null:
			_item_definitions.append(definition)

	_item_definitions.sort_custom(
		func(a: FactoryItemDefinition, b: FactoryItemDefinition) -> bool:
			return _display_name_for(a).nocasecmp_to(_display_name_for(b)) < 0
	)

	for definition in _item_definitions:
		item_list.add_item(_display_name_for(definition), definition.texture)

	if not _item_definitions.is_empty():
		item_list.select(0)


func _display_name_for(definition: FactoryItemDefinition) -> String:
	if not definition.item_name.is_empty():
		return definition.item_name
	return str(FactoryItemDefinition.FactoryItemID.keys()[definition.item_key])


func _on_faith_changed(current_faith: float, max_faith: float) -> void:
	_sync_faith_ui(current_faith, max_faith)


func _sync_faith_ui(current_faith: float, max_faith: float) -> void:
	faith_spinbox.max_value = max_faith
	faith_value_label.text = "%.0f / %.0f" % [current_faith, max_faith]
	if not faith_spinbox.get_line_edit().has_focus():
		faith_spinbox.value = current_faith


func _on_set_faith_pressed() -> void:
	_apply_faith_value(faith_spinbox.value)


func _on_faith_submitted(_text: String) -> void:
	faith_spinbox.apply()
	_apply_faith_value(faith_spinbox.value)


func _apply_faith_value(value: float) -> void:
	if _context != null and _context.faith != null:
		_context.faith.set_faith(value)


func _on_item_selected(_index: int) -> void:
	_update_controls()


func _on_debug_area_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (
		event.button_index == MOUSE_BUTTON_WHEEL_UP
		or event.button_index == MOUSE_BUTTON_WHEEL_DOWN
	):
		get_viewport().set_input_as_handled()


func _on_item_activated(index: int) -> void:
	if index >= 0 and index < _item_definitions.size():
		_spawn_item(_item_definitions[index])


func _on_spawn_item_pressed() -> void:
	var selected := item_list.get_selected_items()
	if selected.is_empty():
		return
	var index := selected[0]
	if index >= 0 and index < _item_definitions.size():
		_spawn_item(_item_definitions[index])


func _spawn_item(definition: FactoryItemDefinition) -> void:
	if (
		definition == null
		or _context == null
		or _context.factory == null
		or _context.factory.item_spawner == null
		or _context.grid == null
		or _context.player == null
	):
		return
	var cell := _context.grid.world_to_cell(_context.player.global_position)
	cell.y = 0
	_context.factory.item_spawner.spawn_factory_item_at_cell(definition, cell)


func _update_controls() -> void:
	var has_faith := _context != null and _context.faith != null
	set_faith_button.disabled = not has_faith
	faith_spinbox.editable = has_faith
	var can_spawn := (
		_context != null
		and _context.factory != null
		and _context.factory.item_spawner != null
		and _context.grid != null
		and _context.player != null
		and not item_list.get_selected_items().is_empty()
	)
	spawn_item_button.disabled = not can_spawn
