## Shows the telescope's current repair stage and how many of the required
## items have been supplied.
class_name TelescopePanel
extends MachineUIPanel

@export var item_progress_scene: PackedScene
@export var repair_title_label: Label
@export var repair_details_label: Label
@export var repair_texture: TextureRect
@export var hint_parent: HBoxContainer
@export var ingredients_parent: VBoxContainer
@export var repair_button: Button
@export var repair_progress_bar: ProgressBar

var _telescope: Telescope
var _rows: Dictionary[FactoryItemDefinition, ItemProgressUI] = {}


func _ready() -> void:
	repair_button.pressed.connect(_on_repair_pressed)


func _on_open() -> void:
	var telescope_machine := machine as TelescopeMachine
	var assembly := machine.machine_assembly as TelescopeAssembly
	assert(
		telescope_machine != null and assembly != null and assembly.telescope != null,
		"TelescopePanel requires a TelescopeMachine in a TelescopeAssembly",
	)
	_telescope = assembly.telescope
	telescope_machine.input_supplied.connect(_on_input_supplied)
	telescope_machine.repair_completed.connect(close_requested.emit)
	telescope_machine.factory_ticked.connect(_on_factory_ticked)
	_telescope.stage_changed.connect(_refresh)
	_refresh()
	_update_repair_button()


func _on_close() -> void:
	var telescope_machine := machine as TelescopeMachine
	if is_instance_valid(telescope_machine):
		if telescope_machine.input_supplied.is_connected(_on_input_supplied):
			telescope_machine.input_supplied.disconnect(_on_input_supplied)
		if telescope_machine.factory_ticked.is_connected(_on_factory_ticked):
			telescope_machine.factory_ticked.disconnect(_on_factory_ticked)
		if telescope_machine.repair_completed.is_connected(close_requested.emit):
			telescope_machine.repair_completed.disconnect(close_requested.emit)
	if is_instance_valid(_telescope) and _telescope.stage_changed.is_connected(_refresh):
		_telescope.stage_changed.disconnect(_refresh)
	_telescope = null
	_rows.clear()


func _refresh() -> void:
	_clear(hint_parent)
	_clear(ingredients_parent)
	_rows.clear()

	var stage := _telescope.get_current_stage()
	if stage == null:
		repair_title_label.text = "Fully repaired"
		repair_details_label.text = ""
		repair_texture.texture = null
		_update_repair_button()
		return

	repair_title_label.text = stage.title
	repair_details_label.text = stage.details

	var view := _telescope.get_current_view()
	if view != null:
		repair_texture.texture = view.texture
		for zone: TelescopeZone in view.zones:
			hint_parent.add_child(_make_hint_icon(zone.area_of_interest.texture))

	var telescope_machine := machine as TelescopeMachine
	for input in stage.recipe.inputs:
		var progress_ui := item_progress_scene.instantiate() as ItemProgressUI
		progress_ui.item = input.item
		progress_ui.quantity_needed = input.amount
		progress_ui.quantity_supplied = telescope_machine.get_supplied(input.item)
		ingredients_parent.add_child(progress_ui)
		_rows[input.item] = progress_ui
	_update_repair_button()


func _make_hint_icon(texture: Texture2D) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = Vector2(32, 32)
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return rect


func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _on_input_supplied(item: FactoryItemDefinition, total: int) -> void:
	if _rows.has(item):
		_rows[item].update_quantity(total)
	_update_repair_button()


func _update_repair_button() -> void:
	var telescope_machine := machine as TelescopeMachine
	var stage := _telescope.get_current_stage()
	repair_button.visible = stage != null
	repair_button.disabled = not telescope_machine.can_repair()
	repair_button.text = "Repairing..." if telescope_machine.is_repairing() else "Repair"
	repair_progress_bar.visible = telescope_machine.is_repairing()
	repair_progress_bar.value = telescope_machine.get_processing_progress()


func _on_repair_pressed() -> void:
	var telescope_machine := machine as TelescopeMachine
	if telescope_machine == null:
		return
	telescope_machine.request_repair()
	_update_repair_button()


func _on_factory_ticked(_machine: Machine, _delta: float) -> void:
	_update_repair_button()
