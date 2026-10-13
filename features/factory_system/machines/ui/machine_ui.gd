class_name MachineUI
extends Control

signal closed

@export var title_label: Label
@export var close_button: Button
@export var tabs: TabContainer

var machine: Machine
var _panels: Array[MachineUIPanel] = []


func open(p_machine: Machine, panel_scenes: Array[PackedScene]) -> void:
	close()
	if p_machine == null:
		return
	machine = p_machine
	machine.tree_exiting.connect(close)
	machine.blueprint_constructed.connect(close)
	title_label.text = String(machine.get_parent().name).capitalize()
	for scene in panel_scenes:
		if scene == null:
			continue
		var panel := scene.instantiate() as MachineUIPanel
		assert(panel != null, "Machine UI panel scenes must have a MachineUIPanel root")
		tabs.add_child(panel)
		tabs.set_tab_title(tabs.get_tab_count() - 1, panel.tab_title)
		panel.open(machine)
		_panels.append(panel)
	show()


func close() -> void:
	hide()
	if machine == null:
		return
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
	closed.emit()


func _ready() -> void:
	close_button.pressed.connect(close)
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
