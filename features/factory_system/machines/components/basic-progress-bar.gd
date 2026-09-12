class_name BasicProgressBar
extends Node3D

@export var machine: BasicMachine
@export var viewport: SubViewport
@export var progress_bar: ProgressBar
@export var display: Sprite3D


func _ready() -> void:
	if viewport != null and display != null:
		display.texture = viewport.get_texture()

	if not machine.factory_ticked.is_connected(_on_machine_factory_ticked):
		machine.factory_ticked.connect(_on_machine_factory_ticked)

	_refresh()


func _on_machine_factory_ticked(ticked_machine: Machine, _delta: float) -> void:
	_refresh()


func _refresh() -> void:
	if progress_bar == null:
		visible = false
		return

	if not is_instance_valid(machine) or not machine.is_processing_recipe():
		progress_bar.value = 0.0
		visible = false
		return

	progress_bar.value = machine.get_processing_progress()
	visible = true
