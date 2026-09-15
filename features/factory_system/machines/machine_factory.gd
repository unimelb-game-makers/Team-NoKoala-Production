class_name MachineFactory

enum MachineType {
	DEMO,
	CONVEYOR,
}

const _SCENES: Dictionary = {
	MachineType.DEMO: preload(
		"res://features/factory_system/machines/machine_runtime/demo_machine.tscn"
	),
	MachineType.CONVEYOR: preload(
		"res://features/factory_system/machines/machine_runtime/demo_conveyor_belt.tscn"
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


static func create_block_data(definition: MachineDefinition) -> BlockData:
	var block_data := BlockData.new()

	for machine_cell in definition.cells:
		block_data.footprint.append(machine_cell.local_cell_offset)
		if machine_cell.can_overlap:
			block_data.overlap_cells.append(machine_cell.local_cell_offset)

	return block_data
