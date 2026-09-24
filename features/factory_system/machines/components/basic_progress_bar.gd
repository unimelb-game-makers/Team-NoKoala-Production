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
@export var status_label: Label
@export var display: Sprite3D
@export_range(0.01, 10.0, 0.01) var world_width := 1.0
@export var materials_colour := Color(0.12, 0.5, 1.0, 1.0)
@export var work_colour := Color(0.3, 0.9, 0.42, 1.0)

var _fill_style: StyleBoxFlat


func _ready() -> void:
	if viewport != null and display != null:
		display.texture = viewport.get_texture()
		_apply_world_size()
	_cache_fill_style()

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

	var phase := Machine.ProgressPhase.NONE
	if is_instance_valid(machine):
		phase = machine.get_progress_phase()

	if phase == Machine.ProgressPhase.NONE:
		progress_bar.value = 0.0
		if status_label != null:
			status_label.text = ""
		visible = false
		if viewport != null:
			viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return

	progress_bar.value = machine.get_processing_progress()
	if status_label != null:
		status_label.text = machine.get_progress_text()
	_set_fill_colour(
		materials_colour
		if phase == Machine.ProgressPhase.MATERIALS
		else work_colour
	)
	visible = true
	if viewport != null:
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func _apply_world_size() -> void:
	if viewport == null or display == null or viewport.size.x <= 0:
		return

	display.fixed_size = false
	display.pixel_size = world_width / float(viewport.size.x)


func _cache_fill_style() -> void:
	if progress_bar == null:
		return
	var current := progress_bar.get_theme_stylebox(&"fill") as StyleBoxFlat
	if current != null:
		_fill_style = current.duplicate() as StyleBoxFlat
	else:
		_fill_style = StyleBoxFlat.new()
	progress_bar.add_theme_stylebox_override(&"fill", _fill_style)


func _set_fill_colour(colour: Color) -> void:
	if _fill_style == null:
		_cache_fill_style()
	if _fill_style != null:
		_fill_style.bg_color = colour
