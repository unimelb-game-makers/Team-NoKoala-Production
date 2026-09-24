class_name MachineFactory

enum MachineType {
	DEMO,
	CONVEYOR,
	RITUAL,
	SPIRIT_RITUAL,
	RESOURCE_AREA,
	CARPENTER,
	MASON,
}

const _SCENES: Dictionary = {
	MachineType.DEMO: preload(
		"res://features/factory_system/machines/machine_scenes/demo_machine.tscn"
	),
	MachineType.CONVEYOR: preload(
		"res://features/factory_system/machines/machine_scenes/demo_conveyor_belt.tscn"
	),
	MachineType.RITUAL: preload(
		"res://features/factory_system/machines/machine_scenes/demo_ritual.tscn"
	),
	MachineType.SPIRIT_RITUAL: preload(
		"res://features/factory_system/machines/machine_scenes/spirit_ritual.tscn"
	),
	MachineType.RESOURCE_AREA: preload(
		"res://features/resource_area/scenes/iron_ore_resourcearea.tscn"
	),
	MachineType.CARPENTER: preload(
		"res://features/factory_system/machines/machine_scenes/carpenter.tscn"
	),
	MachineType.MASON: preload(
		"res://features/factory_system/machines/machine_scenes/mason_bench.tscn"
	),


}
static func create_machine(type: MachineType) -> MachineAssembly:
	var scene: PackedScene = _SCENES[type]
	var assembly := scene.instantiate() as MachineAssembly
	assert(assembly != null, "Machine assembly scene must have a MachineAssembly root")
	assert(assembly.block != null, "MachineAssembly requires a Block component")
	assert(assembly.machine != null, "MachineAssembly requires a Machine component")
	assert(assembly.machine.definition != null, "Machine requires a MachineDefinition")

	var validation_errors := assembly.machine.definition.get_validation_errors()
	assert(
		validation_errors.is_empty(),
		"Invalid machine definition:\n- %s" % "\n- ".join(validation_errors),
	)

	assembly.block.block_data = create_block_data(assembly.machine.definition)
	return assembly


static func machine_type_for_definition(definition: MachineDefinition) -> int:
	if definition == null:
		return -1
	for machine_type in _SCENES:
		var scene: PackedScene = _SCENES[machine_type]
		var assembly := scene.instantiate() as MachineAssembly
		var matches := assembly.machine.definition == definition
		assembly.free()
		if matches:
			return machine_type
	return -1


static func create_block_data(definition: MachineDefinition) -> BlockData:
	var block_data := BlockData.new()

	for machine_cell in definition.cells:
		block_data.footprint.append(machine_cell.local_cell_offset)
		if machine_cell.can_overlap:
			block_data.overlap_cells.append(machine_cell.local_cell_offset)

	return block_data
