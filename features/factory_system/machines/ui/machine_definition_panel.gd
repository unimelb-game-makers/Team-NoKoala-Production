class_name MachineDefinitionPanel
extends CenterContainer

const MATERIAL_ICON_SIZE := Vector2(24, 24)

@export var definition: MachineDefinition
@export var name_label: Label
@export var description_label: Label
@export var construction_time_label: Label
@export var materials_list: VBoxContainer
@export var recipe_picker: OptionButton
@export var recipe_panel: RecipePanel

var _recipes: Array[ProductionRecipe] = []


func _ready() -> void:
	recipe_picker.item_selected.connect(_on_recipe_selected)
	if get_tree().current_scene == self:
		display(definition)


func display(p_definition: MachineDefinition) -> void:
	definition = p_definition
	if definition == null:
		name_label.text = "No machine definition"
		description_label.text = ""
		construction_time_label.text = ""
	else:
		var machine_name := String(definition.machine_name)
		var machine_description := String(definition.machine_description)
		name_label.text = machine_name if not machine_name.is_empty() else "Unnamed machine"
		description_label.text = (
			machine_description if not machine_description.is_empty() else "No description"
		)
		construction_time_label.text = (
			"Construction time: %.1fs" % definition.construction_time_seconds
		)
	_display_materials()
	_build_recipe_picker()
	if _recipes.is_empty():
		recipe_picker.select(0)
		recipe_panel.display(null, false, false)
		recipe_panel.hide()
	else:
		recipe_picker.select(1)
		_on_recipe_selected(1)


func _display_materials() -> void:
	for child in materials_list.get_children():
		materials_list.remove_child(child)
		child.queue_free()
	if definition != null:
		for material in definition.construction_materials:
			if material == null or material.item == null:
				continue
			var row := HBoxContainer.new()
			if material.item.texture != null:
				var icon := TextureRect.new()
				icon.texture = material.item.texture
				icon.custom_minimum_size = MATERIAL_ICON_SIZE
				icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				row.add_child(icon)
			var label := Label.new()
			label.text = "%s x%d" % [material.item.item_name, material.amount]
			row.add_child(label)
			materials_list.add_child(row)
	if materials_list.get_child_count() == 0:
		var none := Label.new()
		none.text = "None"
		materials_list.add_child(none)


func _build_recipe_picker() -> void:
	_recipes.clear()
	recipe_picker.clear()
	recipe_picker.add_item("Select a recipe")
	recipe_picker.set_item_disabled(0, true)
	if definition != null:
		for recipe in definition.recipes:
			if recipe == null:
				continue
			_recipes.append(recipe)
			var title := recipe.display_name.strip_edges()
			if title.is_empty():
				title = String(recipe.recipe_id)
			if title.is_empty():
				title = "Unnamed recipe"
			recipe_picker.add_item(title)
	recipe_picker.disabled = _recipes.is_empty()
	if _recipes.is_empty():
		recipe_picker.set_item_text(0, "No recipes")


func _on_recipe_selected(index: int) -> void:
	if index < 1 or index > _recipes.size():
		recipe_panel.hide()
		return
	recipe_panel.display(_recipes[index - 1], false, false)
	recipe_panel.show()
