class_name MachineInputShadows
extends Node3D

## Optional machine component that previews missing recipe inputs at their cells.
@export var height_above_cell := 0.7
@export var icon_pixel_size := 0.015
@export var refresh_interval := 0.1
@export var shadow_color := Color(0.6, 0.8, 1.0, 0.55)

var machine: Machine
var factory_manager: FactoryManager
var _elapsed := 0.0
var _shadows: Dictionary = {}


func configure(p_machine: Machine, p_factory_manager: FactoryManager) -> void:
	machine = p_machine
	factory_manager = p_factory_manager
	if is_node_ready():
		_refresh()


func _ready() -> void:
	_refresh()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < refresh_interval:
		return
	_elapsed = 0.0
	_refresh()


func _refresh() -> void:
	var desired := _get_missing_inputs()
	for key in _shadows.keys():
		if desired.has(key):
			continue
		_shadows[key].queue_free()
		_shadows.erase(key)

	var keys_by_cell := {}
	for key in desired:
		var input: Dictionary = desired[key]
		var cell: Vector3i = input.cell
		if not keys_by_cell.has(cell):
			keys_by_cell[cell] = []
		keys_by_cell[cell].append(key)

	for cell in keys_by_cell:
		var keys: Array = keys_by_cell[cell]
		for index in keys.size():
			var key: String = keys[index]
			var item: FactoryItemDefinition = desired[key].item
			if not _shadows.has(key):
				_shadows[key] = _create_shadow(item)
			var sprite: Sprite3D = _shadows[key]
			var offset := (float(index) - float(keys.size() - 1) / 2.0) * 0.4
			var world_position := factory_manager.grid.cell_to_world(cell)
			world_position.y += height_above_cell
			world_position += global_transform.basis.x.normalized() * offset
			sprite.global_position = world_position


func _get_missing_inputs() -> Dictionary:
	var desired := {}
	if machine == null or factory_manager == null or factory_manager.grid == null:
		return desired
	if machine.definition == null or machine.machine_assembly == null:
		return desired
	if machine.disabled or machine.is_processing_recipe():
		return desired

	for recipe in machine.enabled_recipes:
		if not machine.can_process_recipe(recipe):
			continue
		for requirement in recipe.inputs:
			if requirement == null or requirement.item == null or requirement.item.texture == null:
				continue
			var cells := machine.get_cells_for_port(
				MachineCellDefinition.Role.INPUT,
				requirement.port_id,
			)
			if cells.is_empty():
				continue
			if machine.get_delivered_input_amount(requirement.item, cells, factory_manager) >= requirement.amount:
				continue
			for cell in cells:
				if _has_item_at_cell(cell, requirement.item):
					continue
				var key := "%s:%d" % [cell, requirement.item.get_instance_id()]
				desired[key] = {"cell": cell, "item": requirement.item}
	return desired


func _has_item_at_cell(cell: Vector3i, item: FactoryItemDefinition) -> bool:
	for processable in factory_manager.get_processables_at(cell):
		var factory_item := processable as FactoryItem
		if (
			factory_item != null
			and factory_item.stack != null
			and factory_item.stack.item_definition == item
			and factory_item.is_available_for_processing()
		):
			return true
	return false


func _create_shadow(item: FactoryItemDefinition) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.name = "InputShadow"
	sprite.texture = item.texture
	sprite.pixel_size = icon_pixel_size
	var scale_factor := 32.0 / maxf(sprite.texture.get_width(), sprite.texture.get_height())
	sprite.scale = 2.0 * Vector3.ONE * scale_factor
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.no_depth_test = true
	sprite.render_priority = 10
	sprite.modulate = shadow_color
	add_child(sprite)
	return sprite
