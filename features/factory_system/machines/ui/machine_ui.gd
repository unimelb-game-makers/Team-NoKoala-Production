class_name MachineUI
extends Control

signal closed

@export var title_label: Label
@export var close_button: Button
@export var tabs: TabContainer
@export var dismantle_button: Button
@export var dismantle_status: Label

var machine: Machine
var assembly: MachineAssembly
var _panels: Array[MachineUIPanel] = []
var _dismantle_component: DismantleComponent


func open(p_assembly: MachineAssembly) -> void:
	close()
	if p_assembly == null or p_assembly.is_queued_for_deletion():
		return
	var ui_machine := p_assembly.get_ui_machine()
	if ui_machine == null:
		return
	assembly = p_assembly
	machine = ui_machine
	assembly.removing_from_world.connect(close)
	machine.tree_exiting.connect(close)
	machine.blueprint_constructed.connect(close)
	title_label.text = String(assembly.name).capitalize()
	for scene in assembly.get_ui_panels():
		if scene == null:
			continue
		var panel := scene.instantiate() as MachineUIPanel
		assert(panel != null, "Machine UI panel scenes must have a MachineUIPanel root")
		tabs.add_child(panel)
		tabs.set_tab_title(tabs.get_tab_count() - 1, panel.tab_title)
		panel.open(assembly)
		_panels.append(panel)
	_dismantle_component = assembly.dismantle_component
	if _dismantle_component != null:
		_dismantle_component.changed.connect(_refresh_dismantle_button)
	_refresh_dismantle_button()
	show()


func close() -> void:
	hide()
	if machine == null:
		return
	if (
		is_instance_valid(_dismantle_component)
		and _dismantle_component.changed.is_connected(_refresh_dismantle_button)
	):
		_dismantle_component.changed.disconnect(_refresh_dismantle_button)
	_dismantle_component = null
	if is_instance_valid(assembly) and assembly.removing_from_world.is_connected(close):
		assembly.removing_from_world.disconnect(close)
	if is_instance_valid(machine) and machine.tree_exiting.is_connected(close):
		machine.tree_exiting.disconnect(close)
	if is_instance_valid(machine) and machine.blueprint_constructed.is_connected(close):
		machine.blueprint_constructed.disconnect(close)
	for panel in _panels:
		panel.close()
		tabs.remove_child(panel)
		panel.queue_free()
	_panels.clear()
	machine = null
	assembly = null
	closed.emit()


func _ready() -> void:
	close_button.pressed.connect(close)
	dismantle_button.pressed.connect(_on_dismantle_pressed)
	hide()


func _refresh_dismantle_button() -> void:
	dismantle_status.hide()
	dismantle_button.visible = is_instance_valid(_dismantle_component)
	if not dismantle_button.visible:
		return
	dismantle_button.disabled = not _dismantle_component.can_dismantle()
	if assembly.is_blueprint_active():
		dismantle_button.text = "Cancel construction"
		dismantle_button.tooltip_text = "Cancel construction. Supplied materials will remain on the ground."
		return
	dismantle_button.text = "Dismantle"
	var materials := PackedStringArray()
	for stack in _dismantle_component.get_refund():
		materials.append("%s × %d" % [stack.item_definition.item_name, stack.quantity])
	dismantle_button.tooltip_text = (
		"Remove this machine. No dismantle materials to return."
		if materials.is_empty() else
		"Remove this machine and return these materials to the ground:\n" + "\n".join(materials)
	)


func _on_dismantle_pressed() -> void:
	if is_instance_valid(_dismantle_component) and not _dismantle_component.try_dismantle():
		dismantle_status.text = "Could not dismantle this machine."
		dismantle_status.show()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
