## Base class for a panel shown as a tab inside MachineUI.
## Subclasses implement _on_open/_on_close to bind to and release the machine.
class_name MachineUIPanel
extends Control

## Emitted when the panel wants the machine UI to close, e.g. to hand over to another view.
signal close_requested

## Title shown on this panel's tab
@export var tab_title := "Panel"

var machine: Machine


func open(p_machine: Machine) -> void:
	close()
	if p_machine == null:
		return
	machine = p_machine
	_on_open()


func close() -> void:
	if machine == null:
		return
	_on_close()
	machine = null


func _on_open() -> void:
	pass


func _on_close() -> void:
	pass
