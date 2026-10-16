## Lets the player order spirits to harvest a resource area, and shows how the
## harvest is going.
class_name HarvestPanel
extends MachineUIPanel

const ITEM_ICON_SIZE := Vector2(24, 24)

@export var name_label: Label
@export var yield_list: VBoxContainer
@export var duration_label: Label
@export var amount_spin_box: SpinBox
@export var forever_check_box: CheckBox
@export var status_label: Label
@export var progress_bar: ProgressBar


func _ready() -> void:
	amount_spin_box.value_changed.connect(_on_amount_changed)
	forever_check_box.toggled.connect(_on_forever_toggled)


func _on_open() -> void:
	var area := machine as ResourceAreaMachine
	assert(area != null, "HarvestPanel requires a ResourceAreaMachine")
	area.factory_ticked.connect(_on_factory_ticked)
	area.harvest_order_changed.connect(_refresh)
	_build(area)
	_refresh()


func _on_close() -> void:
	var area := machine as ResourceAreaMachine
	if not is_instance_valid(area):
		return
	if area.factory_ticked.is_connected(_on_factory_ticked):
		area.factory_ticked.disconnect(_on_factory_ticked)
	if area.harvest_order_changed.is_connected(_refresh):
		area.harvest_order_changed.disconnect(_refresh)


func _build(area: ResourceAreaMachine) -> void:
	for child in yield_list.get_children():
		yield_list.remove_child(child)
		child.queue_free()

	var machine_name := String(area.definition.machine_name) if area.definition != null else ""
	name_label.text = machine_name if not machine_name.is_empty() else "Resource area"

	var recipe := area.get_recipe()
	if recipe == null:
		duration_label.text = ""
		return
	duration_label.text = "Time per harvest: %.1fs" % recipe.duration_seconds
	for output in recipe.outputs:
		if output != null and output.item != null:
			_add_yield_row(output)


func _add_yield_row(output: RecipeItemAmount) -> void:
	var row := HBoxContainer.new()
	if output.item.texture != null:
		var icon := TextureRect.new()
		icon.texture = output.item.texture
		icon.custom_minimum_size = ITEM_ICON_SIZE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
	var label := Label.new()
	label.text = "%s x%d" % [output.item.item_name, output.amount]
	row.add_child(label)
	yield_list.add_child(row)


func _refresh() -> void:
	var area := machine as ResourceAreaMachine
	if area == null:
		return
	amount_spin_box.set_value_no_signal(area.harvest_target)
	amount_spin_box.editable = not area.harvest_forever
	forever_check_box.set_pressed_no_signal(area.harvest_forever)

	if area.harvest_forever:
		status_label.text = "Harvesting forever"
	elif area.harvest_target > 0:
		status_label.text = "%d left to harvest" % area.harvest_target
	else:
		status_label.text = "No harvest order"
	progress_bar.value = area.get_processing_progress()


func _on_amount_changed(value: float) -> void:
	var area := machine as ResourceAreaMachine
	if area != null:
		area.set_harvest_target(int(value))


func _on_forever_toggled(pressed: bool) -> void:
	var area := machine as ResourceAreaMachine
	if area != null:
		area.set_harvest_forever(pressed)


func _on_factory_ticked(_machine: Machine, _delta: float) -> void:
	_refresh()
