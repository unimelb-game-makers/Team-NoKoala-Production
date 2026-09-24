class_name BasicProgressBar
extends Node3D

@export var machine: Machine:
	set(value):
		if machine == value:
			return
		_disconnect_machine()
		machine = value
		if is_node_ready():
			_connect_machine()
			_refresh()
@export var viewport: SubViewport
@export var progress_bar: ProgressBar
@export var display: Sprite3D
@export_range(0.01, 10.0, 0.01) var world_width := 1.0


func _ready() -> void:
	if viewport != null and display != null:
		display.texture = viewport.get_texture()
		_apply_world_size()

	_connect_machine()
	_refresh()


func _exit_tree() -> void:
	_disconnect_machine()


func _connect_machine() -> void:
	if not is_instance_valid(machine):
		return
	if not machine.factory_ticked.is_connected(_on_machine_factory_ticked):
		machine.factory_ticked.connect(_on_machine_factory_ticked)


func _disconnect_machine() -> void:
	if not is_instance_valid(machine):
		return
	if machine.factory_ticked.is_connected(_on_machine_factory_ticked):
		machine.factory_ticked.disconnect(_on_machine_factory_ticked)


func _on_machine_factory_ticked(_machine: Machine, _delta: float) -> void:
	_refresh()


func _refresh() -> void:
	if progress_bar == null:
		visible = false
		return

	if not is_instance_valid(machine) or not machine.is_processing_recipe():
		progress_bar.value = 0.0
		visible = false
		if viewport != null:
			viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return

	progress_bar.value = machine.get_processing_progress()
	visible = true
	if viewport != null:
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func _apply_world_size() -> void:
	if viewport == null or display == null or viewport.size.x <= 0:
		return

	display.fixed_size = false
	display.pixel_size = world_width / float(viewport.size.x)
