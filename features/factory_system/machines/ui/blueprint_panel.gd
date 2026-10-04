## Shows construction materials supplied to a BlueprintMachine and its progress.
class_name BlueprintPanel
extends MachineUIPanel

const MATERIAL_ICON_SIZE := Vector2(24, 24)
const COMPLETE_COLOUR := Color(0.45, 1, 0.45)

@export var name_label: Label
@export var construction_time_label: Label
@export var materials_list: VBoxContainer
@export var progress_bar: ProgressBar
@export var status_label: Label

var _amount_labels: Dictionary[RecipeItemAmount, Label] = {}


func _on_open() -> void:
	machine.factory_ticked.connect(_on_factory_ticked)
	_build()
	_refresh()


func _on_close() -> void:
	if (
		is_instance_valid(machine)
		and machine.factory_ticked.is_connected(_on_factory_ticked)
	):
		machine.factory_ticked.disconnect(_on_factory_ticked)
	_clear_materials()


func _build() -> void:
	_clear_materials()
	var definition := machine.definition
	if definition == null:
		name_label.text = "No machine definition"
		construction_time_label.text = ""
	else:
		var machine_name := String(definition.machine_name)
		name_label.text = (
			machine_name if not machine_name.is_empty() else "Unnamed machine"
		)
		construction_time_label.text = (
			"Construction time: %.1fs" % definition.construction_time_seconds
		)
		for material in definition.construction_materials:
			if material == null or material.item == null:
				continue
			_add_material_row(material)

	if materials_list.get_child_count() == 0:
		var none := Label.new()
		none.text = "None"
		materials_list.add_child(none)


func _add_material_row(material: RecipeItemAmount) -> void:
	var row := HBoxContainer.new()
	if material.item.texture != null:
		var icon := TextureRect.new()
		icon.texture = material.item.texture
		icon.custom_minimum_size = MATERIAL_ICON_SIZE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
	var item_label := Label.new()
	item_label.text = material.item.item_name
	item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(item_label)
	var amount := Label.new()
	row.add_child(amount)
	materials_list.add_child(row)
	_amount_labels[material] = amount


func _clear_materials() -> void:
	for child in materials_list.get_children():
		materials_list.remove_child(child)
		child.queue_free()
	_amount_labels.clear()


func _refresh() -> void:
	var blueprint := machine as BlueprintMachine
	for material: RecipeItemAmount in _amount_labels:
		var supplied := (
			blueprint.get_supplied_material_amount(material.item)
			if blueprint != null
			else 0
		)
		supplied = mini(supplied, material.amount)
		var label := _amount_labels[material]
		label.text = "%d/%d" % [supplied, material.amount]
		label.modulate = (
			COMPLETE_COLOUR if supplied >= material.amount else Color.WHITE
		)

	progress_bar.value = machine.get_processing_progress()
	status_label.text = machine.get_progress_text()


func _on_factory_ticked(_machine: Machine, _delta: float) -> void:
	_refresh()
