class_name MachineFactory
extends Node

## Scenes are the editor-authored catalog. Callers use definitions.
@export var machine_scenes: Array[PackedScene] = []
@export var default_machine_definition: MachineDefinition

var _scenes_by_definition_path: Dictionary[String, PackedScene] = {}
var _definitions: Array[MachineDefinition] = []
var _index_built := false


func get_machine_definitions() -> Array[MachineDefinition]:
	_ensure_index()
	return _definitions.duplicate()


func has_machine_definition(definition: MachineDefinition) -> bool:
	return get_machine_scene(definition) != null

func get_default_machine_definition() -> MachineDefinition:
	_ensure_index()
	if has_machine_definition(default_machine_definition):
		return default_machine_definition
	return _definitions[0] if not _definitions.is_empty() else null

func get_machine_scene(definition: MachineDefinition) -> PackedScene:
	_ensure_index()
	if definition == null or definition.resource_path.is_empty():
		return null
	return _scenes_by_definition_path.get(definition.resource_path)

func create_machine(definition: MachineDefinition) -> MachineAssembly:
	var scene := get_machine_scene(definition)
	if scene == null:
		return null
		
	var assembly := _instantiate_scene(scene)

	if assembly == null or assembly.block == null or assembly.machine == null or assembly.machine.definition == null:
		if assembly != null:
			assembly.free()
		return null
	assembly.block.block_data = _create_block_data(assembly.machine.definition)
	return assembly

func _instantiate_scene(scene: PackedScene) -> MachineAssembly:
	var root := scene.instantiate()
	var assembly := root as MachineAssembly
	if assembly == null and root != null:
		root.free()
	return assembly

func _create_block_data(definition: MachineDefinition) -> BlockData:
	var block_data := BlockData.new()
	for machine_cell in definition.cells:
		if machine_cell == null:
			continue
		block_data.footprint.append(machine_cell.local_cell_offset)
		if machine_cell.can_overlap:
			block_data.overlap_cells.append(machine_cell.local_cell_offset)
	return block_data

func _ensure_index() -> void:
	if _index_built:
		return
	_index_built = true
	_scenes_by_definition_path.clear()
	_definitions.clear()
	for scene in machine_scenes:
		if scene == null:
			continue
		var assembly := _instantiate_scene(scene)
		if assembly == null or assembly.block == null or assembly.machine == null or assembly.machine.definition == null:
			continue
		var definition := assembly.machine.definition as MachineDefinition
		var path := definition.resource_path
		if path.is_empty():
			push_warning("Machine definition must be an external resource for stable lookup")
			continue
		elif _scenes_by_definition_path.has(path):
			push_warning("Machine definition %s already found in dictionary" % definition.machine_name)
			continue
		_scenes_by_definition_path[path] = scene
		_definitions.append(definition)
		assembly.free()
