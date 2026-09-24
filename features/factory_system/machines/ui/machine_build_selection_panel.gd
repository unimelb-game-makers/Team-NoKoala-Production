class_name MachineBuildSelectionPanel
extends Control

@export var allowed_definitions: Array[MachineDefinition] = []
@export var machine_list: ItemList
@export var definition_panel: MachineDefinitionPanel
@export var build_button: Button
@export var close_button: Button

var placement: MachinePlacementController
var _definitions: Array[MachineDefinition] = []
var _machine_types: Array[int] = []


func _ready() -> void:
	machine_list.item_selected.connect(_on_machine_selected)
	build_button.pressed.connect(_on_build_pressed)
	close_button.pressed.connect(close)
	if get_tree().current_scene == self:
		open()
	else:
		hide()


func configure(p_placement: MachinePlacementController) -> void:
	placement = p_placement
	if is_node_ready():
		_update_build_button()


func open() -> void:
	_rebuild_machine_list()
	show()


func close() -> void:
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _rebuild_machine_list() -> void:
	_definitions.clear()
	_machine_types.clear()
	machine_list.clear()
	for definition in allowed_definitions:
		if definition == null or _definitions.has(definition):
			continue
		var machine_type := MachineFactory.machine_type_for_definition(definition)
		if machine_type < 0:
			push_warning("Machine definition is not registered in MachineFactory: %s" % definition.resource_path)
			continue
		_definitions.append(definition)
		_machine_types.append(machine_type)
		var title := String(definition.machine_name)
		machine_list.add_item(title if not title.is_empty() else "Unnamed machine")
	if _definitions.is_empty():
		definition_panel.display(null)
	else:
		machine_list.select(0)
		definition_panel.display(_definitions[0])
	_update_build_button()


func _on_machine_selected(index: int) -> void:
	if index < 0 or index >= _definitions.size():
		definition_panel.display(null)
	else:
		definition_panel.display(_definitions[index])
	_update_build_button()


func _on_build_pressed() -> void:
	if placement == null:
		return
	var selected := machine_list.get_selected_items()
	if selected.is_empty() or selected[0] >= _machine_types.size():
		return
	placement.select_machine(_machine_types[selected[0]] as MachineFactory.MachineType)
	placement.place_mode = true
	close()


func _update_build_button() -> void:
	var selected := machine_list.get_selected_items()
	build_button.disabled = (
		placement == null
		or selected.is_empty()
		or selected[0] >= _machine_types.size()
	)
