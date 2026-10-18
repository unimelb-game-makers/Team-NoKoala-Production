## Base class for a panel shown as a tab inside MachineUI.
## Subclasses implement _on_open/_on_close to bind to the assembly's capabilities.
class_name MachineUIPanel
extends Control

## Title shown on this panel's tab
@export var tab_title := "Panel"

var machine: Machine
var assembly: MachineAssembly


func open(p_assembly: MachineAssembly) -> void:
	close()
	if p_assembly == null:
		return
	assembly = p_assembly
	machine = assembly.get_ui_machine()
	_on_open()


func close() -> void:
	if assembly == null:
		return
	_on_close()
	machine = null
	assembly = null


func _on_open() -> void:
	pass


func _on_close() -> void:
	pass
