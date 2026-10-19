class_name OfferingStagesPanel
extends MachineUIPanel

@export var stages_list: VBoxContainer
@export var stage_title: Label
@export var stage_status: Label
@export var offering_label: Label
@export var rewards_list: VBoxContainer

var _offering: OfferingMachine
var _selected_stage_index := 0


func _on_open() -> void:
	_offering = machine as OfferingMachine
	if _offering == null:
		_show_empty_state("This panel needs an offering machine")
		return
	if not _offering.stage_completed.is_connected(_on_stage_completed):
		_offering.stage_completed.connect(_on_stage_completed)
	if (
		_offering.recipe_unlocks != null
		and not _offering.recipe_unlocks.recipe_unlocked.is_connected(_on_recipe_unlocked)
	):
		_offering.recipe_unlocks.recipe_unlocked.connect(_on_recipe_unlocked)
	if not _offering.stages.is_empty():
		_selected_stage_index = mini(
			_offering.current_stage_index,
			_offering.stages.size() - 1,
		)
	_rebuild()


func _on_close() -> void:
	if is_instance_valid(_offering):
		if _offering.stage_completed.is_connected(_on_stage_completed):
			_offering.stage_completed.disconnect(_on_stage_completed)
		if (
			_offering.recipe_unlocks != null
			and _offering.recipe_unlocks.recipe_unlocked.is_connected(_on_recipe_unlocked)
		):
			_offering.recipe_unlocks.recipe_unlocked.disconnect(_on_recipe_unlocked)
	_offering = null
	_clear(stages_list)
	_clear(rewards_list)


func _on_stage_completed(stage_index: int, _stage: OfferingStage) -> void:
	if _selected_stage_index == stage_index:
		_selected_stage_index = mini(stage_index + 1, _offering.stages.size() - 1)
	_rebuild()


func _on_recipe_unlocked(_recipe: ProductionRecipe) -> void:
	_refresh_details()


func _select_stage(index: int) -> void:
	_selected_stage_index = index
	_rebuild()


func _rebuild() -> void:
	_clear(stages_list)
	if _offering == null or _offering.stages.is_empty():
		_show_empty_state("No offering stages configured")
		return

	_selected_stage_index = clampi(_selected_stage_index, 0, _offering.stages.size() - 1)
	for index in _offering.stages.size():
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 58)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_pressed = index == _selected_stage_index
		button.tooltip_text = _stage_name(_offering.stages[index])
		button.text = "%02d  %s\n%s" % [
			index + 1,
			_short_stage_name(_offering.stages[index]),
			_stage_state(index),
		]
		button.add_theme_color_override("font_color", _stage_color(index))
		button.pressed.connect(_select_stage.bind(index))
		stages_list.add_child(button)
	_refresh_details()


func _refresh_details() -> void:
	_clear(rewards_list)
	if _offering == null or _offering.stages.is_empty():
		return
	var stage := _offering.stages[_selected_stage_index]
	stage_title.text = "Stage %d: %s" % [
		_selected_stage_index + 1,
		_stage_name(stage),
	]
	stage_status.text = _stage_state(_selected_stage_index)
	stage_status.add_theme_color_override(
		"font_color", _stage_color(_selected_stage_index)
	)
	if stage == null or stage.recipe == null:
		offering_label.text = "Offer: Not configured"
	else:
		offering_label.text = "Offer: %s" % _recipe_name(stage.recipe)

	if stage == null or stage.recipes_to_unlock.is_empty():
		_add_message("No recipes unlock from this stage")
		return
	for recipe in stage.recipes_to_unlock:
		if recipe == null:
			_add_message("Missing reward recipe")
		else:
			_add_reward(recipe)


func _add_reward(recipe: ProductionRecipe) -> void:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rewards_list.add_child(card)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 8)
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)
	var product := _first_product(recipe)
	if product != null and product.texture != null:
		var icon := TextureRect.new()
		icon.texture = product.texture
		icon.custom_minimum_size = Vector2(40, 40)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
	var labels := VBoxContainer.new()
	labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(labels)
	var name_label := Label.new()
	name_label.text = _recipe_name(recipe)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	labels.add_child(name_label)
	var unlocked := _is_reward_unlocked(recipe)
	var status_label := Label.new()
	status_label.text = "Unlocked" if unlocked else "Locked"
	status_label.add_theme_color_override(
		"font_color",
		Color(0.45, 1.0, 0.55) if unlocked else Color(0.65, 0.67, 0.72),
	)
	labels.add_child(status_label)


func _add_message(message: String) -> void:
	var label := Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rewards_list.add_child(label)


func _show_empty_state(message: String) -> void:
	stage_title.text = "Stages"
	stage_status.text = ""
	offering_label.text = ""
	_clear(rewards_list)
	_add_message(message)


func _stage_state(index: int) -> String:
	if index < _offering.current_stage_index:
		return "Unlocked (completed)"
	if index == _offering.current_stage_index:
		return "Unlocked"
	return "Locked"


func _stage_color(index: int) -> Color:
	if index < _offering.current_stage_index:
		return Color(0.45, 1.0, 0.55)
	if index == _offering.current_stage_index:
		return Color(1.0, 0.85, 0.42)
	return Color(0.65, 0.67, 0.72)


func _stage_name(stage: OfferingStage) -> String:
	if stage == null or stage.recipe == null:
		return "Missing offering"
	return _recipe_name(stage.recipe)


func _short_stage_name(stage: OfferingStage) -> String:
	var name := _stage_name(stage)
	return name if name.length() <= 17 else "%s…" % name.substr(0, 16)


func _recipe_name(recipe: ProductionRecipe) -> String:
	if not recipe.display_name.is_empty():
		return recipe.display_name.capitalize()
	return String(recipe.recipe_id).capitalize()


func _first_product(recipe: ProductionRecipe) -> FactoryItemDefinition:
	for output in recipe.outputs:
		if output != null and output.item != null:
			return output.item
	return null


func _is_reward_unlocked(recipe: ProductionRecipe) -> bool:
	if _offering.recipe_unlocks != null:
		return _offering.recipe_unlocks.is_unlocked(recipe)
	return _selected_stage_index < _offering.current_stage_index


func _clear(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
