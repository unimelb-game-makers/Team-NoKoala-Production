class_name MachineFactory

const MACHINE = preload("res://features/factory_system/machines/machine_runtime/demo_machine.tscn")

const machine_scene: Dictionary = {
}


static func create_machine() -> MachineAssembly:

	var assembly := MACHINE.instantiate() as MachineAssembly
	assert(assembly != null, "Machine assembly scene must have a MachineAssembly root")
	assert(assembly.block != null, "MachineAssembly requires a Block component")
	assert(assembly.machine != null, "MachineAssembly requires a Machine component")

	assembly.block.block_data = create_block_data(assembly.machine.definition)
	return assembly



static func create_block_data(definition: MachineDefinition) -> BlockData:
	var block_data := BlockData.new()

	for machine_cell in definition.cells:
		block_data.footprint.append(machine_cell.local_cell_offset)
		if machine_cell.can_overlap:
			block_data.overlap_cells.append(machine_cell.local_cell_offset)

	return block_data
